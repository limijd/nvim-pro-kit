#!/usr/bin/env python3
"""Build and install Tree-sitter parsers from vendored sources."""

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path
from contextlib import contextmanager
from typing import Dict, Iterable, Iterator, List, Optional, Sequence, Set


class BuildError(RuntimeError):
    """Raised when building a parser fails."""


def log(message: str) -> None:
    """Print a status message with flushing enabled."""

    print(message, flush=True)


def progress(scope: str, index: int, total: int, message: str) -> None:
    """Print a formatted progress message for parser processing."""

    log(f"[{scope}][{index}/{total}] {message}")


def format_command(args: Sequence[str]) -> str:
    """Return a human readable representation of a command line."""

    return " ".join(shlex.quote(arg) for arg in args)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compile Tree-sitter parsers from vendored repositories.",
    )
    parser.add_argument(
        "--manifest",
        help="Override the parser manifest path.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify installed parsers match the manifest without rebuilding.",
    )
    prune_group = parser.add_mutually_exclusive_group()
    prune_group.add_argument(
        "--prune",
        dest="prune",
        action="store_true",
        help="Remove compiled parsers that are not listed in the manifest (default).",
    )
    prune_group.add_argument(
        "--no-prune",
        dest="prune",
        action="store_false",
        help="Skip pruning of extraneous parsers.",
    )
    parser.set_defaults(prune=True)
    return parser.parse_args(argv)


def repo_root() -> Path:
    script_path = Path(__file__).resolve()
    for candidate in script_path.parents:
        if (candidate / "nvim").is_dir() and (candidate / "scripts").is_dir():
            return candidate
    raise SystemExit("error: failed to determine repository root from script location")


def load_manifest(path: Path) -> List[str]:
    try:
        raw_lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise SystemExit(f"error: failed to read manifest at {path}: {exc}") from exc

    languages: List[str] = []
    for line in raw_lines:
        stripped = line.split("#", 1)[0].strip()
        if stripped:
            languages.append(stripped)
    return languages


def load_metadata(path: Path) -> Dict[str, Dict[str, object]]:
    if not path.is_file():
        raise SystemExit(f"error: metadata not found at {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"error: failed to decode metadata at {path}: {exc}") from exc


def shared_library_extension() -> str:
    if sys.platform == "darwin":
        return ".so"
    if os.name == "nt":
        return ".dll"
    return ".so"


def has_cpp_sources(files: Iterable[str]) -> bool:
    return any(Path(file).suffix in {".cc", ".cpp", ".cxx"} for file in files)


def parser_archive_path(vendor_root: Path, lang: str) -> Path:
    archive_path = vendor_root / f"{lang}.tar.bz2"
    if not archive_path.is_file():
        raise SystemExit(
            f"error: vendored archive for {lang} is missing at {archive_path}"
        )
    return archive_path


def tar_safe_extract(tar: tarfile.TarFile, destination: Path) -> None:
    destination = destination.resolve()

    def is_within_directory(base: Path, target: Path) -> bool:
        try:
            target.relative_to(base)
        except ValueError:
            return False
        return True

    for member in tar.getmembers():
        member_path = destination / member.name
        if not is_within_directory(destination, member_path.resolve()):
            raise SystemExit(
                "error: attempted path traversal while extracting Tree-sitter archive"
            )
    tar.extractall(destination)


@contextmanager
def parser_sources(
    lang: str, info: Dict[str, object], vendor_root: Path
) -> Iterator[Path]:
    archive_path = parser_archive_path(vendor_root, lang)
    with tempfile.TemporaryDirectory() as tmpdir:
        extract_root = Path(tmpdir)
        try:
            with tarfile.open(archive_path, mode="r:bz2") as tar:
                tar_safe_extract(tar, extract_root)
        except (tarfile.TarError, OSError) as exc:
            raise SystemExit(
                f"error: failed to extract vendored archive for {lang}: {exc}"
            ) from exc

        candidate = extract_root / lang
        if not candidate.is_dir():
            subdirs = [path for path in extract_root.iterdir() if path.is_dir()]
            if len(subdirs) == 1:
                candidate = subdirs[0]
            else:
                raise SystemExit(
                    "error: extracted archive for {lang} does not contain a unique root"
                    .format(lang=lang)
                )

        location = info.get("location")
        location_path = Path(location) if isinstance(location, str) and location else None
        base_dir = candidate / location_path if location_path else candidate
        if not base_dir.is_dir():
            raise SystemExit(
                f"error: expected parser location for {lang} is missing at {base_dir}"
            )

        yield base_dir


def compile_parser(
    lang: str,
    info: Dict[str, object],
    vendor_root: Path,
    runtime_include: Path,
    output_path: Path,
) -> None:
    files = info.get("files")
    if not isinstance(files, list) or not all(isinstance(f, str) for f in files):
        raise BuildError(f"parser {lang} does not list source files to compile")

    compiler = os.environ.get("CC", "cc")
    uses_cpp = has_cpp_sources(files)

    with parser_sources(lang, info, vendor_root) as base_dir:
        missing: List[str] = []
        for rel in files:
            if not (base_dir / rel).is_file():
                missing.append(rel)
        if missing:
            raise BuildError(
                f"parser {lang} is missing required source files: {' '.join(missing)}"
            )

        with tempfile.TemporaryDirectory() as build_dir:
            tmp_output = Path(build_dir) / output_path.name
            args: List[str] = [compiler]
            args.extend(["-I", "./src"])
            args.extend(["-I", str(runtime_include)])
            args.append("-Os")
            if os.name != "nt":
                args.append("-fPIC")

            cxx_standard = (
                str(info.get("cxx_standard")) if info.get("cxx_standard") else None
            )
            if uses_cpp:
                args.append(f"-std={cxx_standard}" if cxx_standard else "-std=c++14")
            else:
                args.append("-std=c11")

            if sys.platform == "darwin":
                args.append("-bundle")
            else:
                args.append("-shared")

            args.extend(["-o", str(tmp_output)])
            args.extend(str(Path(rel)) for rel in files)
            if uses_cpp:
                args.append("-lstdc++")

            log(f"[sync] {lang}: running (cwd={base_dir}) {format_command(args)}")
            try:
                subprocess.run(args, cwd=base_dir, check=True)
            except FileNotFoundError as exc:
                raise BuildError(
                    f"compiler {compiler!r} required to build {lang} not found"
                ) from exc
            except subprocess.CalledProcessError as exc:
                raise BuildError(f"failed to compile parser for {lang}") from exc

            output_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(tmp_output, output_path)


def list_parsers(parser_dir: Path, extension: str) -> Set[str]:
    if not parser_dir.is_dir():
        return set()
    return {path.stem for path in parser_dir.glob(f"*{extension}")}


def list_revisions(info_dir: Path) -> Set[str]:
    if not info_dir.is_dir():
        return set()
    return {path.stem for path in info_dir.glob("*.revision")}


def prune_extras(extra: Iterable[str], parser_dir: Path, info_dir: Path, extension: str) -> None:
    extras = sorted(set(extra))
    if not extras:
        return

    log(f"[sync] Pruning extraneous parsers: {' '.join(extras)}")
    for lang in extras:
        parser_path = parser_dir / f"{lang}{extension}"
        try:
            parser_path.unlink()
        except OSError:
            pass
        revision_path = info_dir / f"{lang}.revision"
        try:
            revision_path.unlink()
        except OSError:
            pass


def write_revision(info_dir: Path, lang: str, revision: Optional[str]) -> None:
    info_dir.mkdir(parents=True, exist_ok=True)
    path = info_dir / f"{lang}.revision"
    text = (revision or "").strip()
    log(f"[sync] {lang}: writing revision {text or '<unknown>'} to {path}")
    path.write_text(text + "\n", encoding="utf-8")


def verify_installation(
    lang: str,
    info: Dict[str, object],
    parser_dir: Path,
    info_dir: Path,
    extension: str,
) -> None:
    parser_path = parser_dir / f"{lang}{extension}"
    if not parser_path.is_file():
        raise SystemExit(f"error: compiled parser missing for {lang} at {parser_path}")

    revision = str(info.get("revision") or "").strip()
    revision_path = info_dir / f"{lang}.revision"
    if revision:
        if not revision_path.is_file():
            raise SystemExit(
                f"error: revision file missing for {lang} at {revision_path}"
            )
        installed = revision_path.read_text(encoding="utf-8").strip()
        if installed != revision:
            raise SystemExit(
                "error: revision mismatch for {lang}: expected {expected} got {actual}".format(
                    lang=lang, expected=revision, actual=installed
                )
            )


def report(
    manifest_langs: Sequence[str],
    installed: Set[str],
    revisions: Set[str],
    *,
    check: bool,
    prune: bool,
    parser_dir: Path,
    info_dir: Path,
    extension: str,
) -> None:
    manifest_set = set(manifest_langs)
    missing = [lang for lang in manifest_langs if lang not in installed]
    extra = (installed | revisions) - manifest_set

    if check:
        status = 0
        if missing:
            sys.stderr.write("Missing Tree-sitter parsers: " + " ".join(missing) + "\n")
            status = 1
        if extra:
            sys.stderr.write(
                "Extraneous Tree-sitter parsers: " + " ".join(sorted(extra)) + "\n"
            )
            status = 1
        if status != 0:
            raise SystemExit(status)
        return

    if prune and extra:
        prune_extras(extra, parser_dir, info_dir, extension)
    elif extra:
        log(
            "[sync] Extraneous Tree-sitter parsers detected (use --prune to remove): "
            + " ".join(sorted(extra))
        )

    if missing:
        sys.stderr.write(
            "Parsers still missing after build: " + " ".join(missing) + "\n"
        )
        raise SystemExit(1)


def main(argv: Sequence[str]) -> None:
    args = parse_args(argv)

    root = repo_root()
    manifest_path = Path(args.manifest) if args.manifest else root / "scripts" / "treesitter-parsers.txt"
    if not manifest_path.is_file():
        raise SystemExit(f"error: manifest not found at {manifest_path}")

    manifest_langs = load_manifest(manifest_path)
    if not manifest_langs:
        raise SystemExit(
            f"error: manifest {manifest_path} does not list any Tree-sitter parsers"
        )

    log(f"[sync] Loaded manifest from {manifest_path} ({len(manifest_langs)} languages)")

    metadata_path = root / "vendor" / "tree-sitter" / "metadata.json"
    metadata = load_metadata(metadata_path)
    vendor_root = metadata_path.parent
    runtime_include = vendor_root / "tree_sitter"
    if not runtime_include.is_dir():
        raise SystemExit(
            f"error: vendored runtime headers not found at {runtime_include}"
        )

    parser_dir = root / "vendor" / "plugins" / "nvim-treesitter" / "parser"
    info_dir = root / "vendor" / "plugins" / "nvim-treesitter" / "parser-info"
    extension = shared_library_extension()

    total = len(manifest_langs)
    if args.check:
        for index, lang in enumerate(manifest_langs, 1):
            if index > 1:
                log("")
            info = metadata.get(lang)
            if not info:
                raise SystemExit(f"error: missing metadata for {lang}")
            progress(
                "sync",
                index,
                total,
                f"Verifying tree-sitter {lang} parser installation...",
            )
            verify_installation(lang, info, parser_dir, info_dir, extension)
    else:
        for index, lang in enumerate(manifest_langs, 1):
            if index > 1:
                log("")
            info = metadata.get(lang)
            if not info:
                raise SystemExit(f"error: missing metadata for {lang}")
            progress(
                "sync",
                index,
                total,
                f"Building tree-sitter {lang} parser...",
            )
            log(f"[sync] {lang}: compiling parser")
            output_path = parser_dir / f"{lang}{extension}"
            try:
                compile_parser(lang, info, vendor_root, runtime_include, output_path)
            except BuildError as exc:
                raise SystemExit(f"error: {exc}") from exc
            revision = str(info.get("revision") or "").strip()
            write_revision(info_dir, lang, revision)

    installed = list_parsers(parser_dir, extension)
    revisions = list_revisions(info_dir)
    report(
        manifest_langs,
        installed,
        revisions,
        check=args.check,
        prune=args.prune,
        parser_dir=parser_dir,
        info_dir=info_dir,
        extension=extension,
    )


if __name__ == "__main__":
    main(sys.argv[1:])
