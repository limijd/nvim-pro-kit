#!/usr/bin/env python3
"""Build Tree-sitter parsers from vendored sources and install them."""

from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Sequence


class BuildError(RuntimeError):
    """Raised when a parser fails to build."""


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build Tree-sitter parsers from vendored sources",
    )
    parser.add_argument(
        "--manifest",
        help="Override the parser manifest path.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify installed parsers without building them.",
    )
    prune_group = parser.add_mutually_exclusive_group()
    prune_group.add_argument(
        "--prune",
        dest="prune",
        action="store_true",
        help="Remove parsers that are not listed in the manifest (default).",
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
    try:
        output = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        raise SystemExit("error: failed to determine git repository root") from exc
    return Path(output.strip())


def load_manifest(path: Path) -> list[str]:
    try:
        raw_lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise SystemExit(f"error: failed to read manifest at {path}: {exc}") from exc

    languages: list[str] = []
    for line in raw_lines:
        stripped = line.split("#", 1)[0].strip()
        if stripped:
            languages.append(stripped)
    return languages


def load_metadata(path: Path) -> tuple[dict[str, dict[str, object]], Path]:
    if not path.is_file():
        raise SystemExit(
            f"error: Tree-sitter metadata not found at {path}. "
            "Run scripts/treesitter-vendor.py first."
        )

    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit(f"error: failed to load metadata from {path}: {exc}") from exc

    if not isinstance(raw, dict):
        raise SystemExit("error: metadata has unexpected structure")

    metadata: dict[str, dict[str, object]] = {}
    for lang, info in raw.items():
        if isinstance(info, dict):
            metadata[lang] = info

    return metadata, path.parent


def library_suffix() -> str:
    if sys.platform == "darwin":
        return ".dylib"
    if os.name == "nt":
        return ".dll"
    return ".so"


def format_command(args: Sequence[str]) -> str:
    return " ".join(shlex.quote(arg) for arg in args)


def log(message: str) -> None:
    print(message)


def log_step(lang: str, message: str) -> None:
    print(f"[{lang}] {message}")


def has_cpp_sources(files: Sequence[str]) -> bool:
    return any(Path(file).suffix in {".cc", ".cpp", ".cxx"} for file in files)


def run_command(
    args: Sequence[str], *, cwd: Path | None, check: bool = True, env: dict[str, str] | None = None
) -> None:
    location = f" (cwd={cwd})" if cwd else ""
    log(f"$ {format_command(args)}{location}")
    subprocess.run(args, cwd=cwd, check=check, env=env)


def compile_with_compiler(
    lang: str,
    files: Sequence[str],
    base_dir: Path,
    output_path: Path,
    *,
    cxx_standard: str | None,
) -> Path:
    compiler = os.environ.get("CC", "cc")
    args: list[str] = [compiler, "-o", str(output_path), "-I", str(base_dir / "src")]
    args.extend(str(Path(file)) for file in files)
    args.append("-Os")

    if has_cpp_sources(files):
        args.append(f"-std={cxx_standard}" if cxx_standard else "-std=c++14")
        args.append("-lstdc++")
    else:
        args.append("-std=c11")

    if sys.platform == "darwin":
        args.append("-bundle")
    else:
        args.append("-shared")

    if os.name != "nt":
        args.append("-fPIC")

    run_command(args, cwd=base_dir)
    return output_path


def compile_with_make(lang: str, base_dir: Path, output_name: str) -> tuple[Path, str]:
    make_path = shutil.which("gmake") or shutil.which("make")
    if not make_path:
        raise BuildError(f"required build tool 'make' not found for parser {lang}")

    env = os.environ.copy()
    env.setdefault("TS", os.environ.get("TS", "true"))

    run_command([make_path], cwd=base_dir, env=env)
    artifact = base_dir / output_name
    if not artifact.exists():
        raise BuildError(
            f"make completed for {lang} but expected artifact {output_name} was not produced"
        )
    return artifact, make_path


def run_make_clean(make_path: str, base_dir: Path) -> None:
    try:
        env = os.environ.copy()
        env.setdefault("TS", os.environ.get("TS", "true"))
        run_command([make_path, "clean"], cwd=base_dir, check=False, env=env)
    except OSError:
        pass


def build_parser(
    lang: str,
    info: dict[str, object],
    vendor_root: Path,
    parser_dir: Path,
    *,
    suffix: str,
) -> Path:
    source_dir = vendor_root / lang
    if not source_dir.is_dir():
        raise BuildError(f"vendored sources for {lang} not found at {source_dir}")

    location = info.get("location")
    location_path = Path(str(location)) if isinstance(location, str) and location else None
    base_dir = source_dir / location_path if location_path else source_dir
    if not base_dir.is_dir():
        raise BuildError(f"expected directory for {lang} at {base_dir} is missing")

    files = info.get("files")
    if not isinstance(files, Sequence) or not all(isinstance(f, str) for f in files):
        raise BuildError(f"metadata for {lang} does not list source files")
    file_list = [str(f) for f in files]

    output_name = f"parser{suffix}"
    artifact_path = base_dir / output_name
    if artifact_path.exists():
        artifact_path.unlink()

    use_makefile = bool(info.get("use_makefile")) or (base_dir / "Makefile").is_file()
    make_path: str | None = None

    log_step(lang, f"Building parser from {base_dir}")
    if use_makefile:
        artifact_path, make_path = compile_with_make(lang, base_dir, output_name)
    else:
        artifact_path = compile_with_compiler(
            lang,
            file_list,
            base_dir,
            artifact_path,
            cxx_standard=str(info.get("cxx_standard")) if info.get("cxx_standard") else None,
        )

    if not artifact_path.exists():
        raise BuildError(f"expected build artifact for {lang} not found at {artifact_path}")

    parser_dir.mkdir(parents=True, exist_ok=True)
    destination = parser_dir / f"{lang}{suffix}"
    if destination.exists():
        destination.unlink()

    log_step(lang, f"Installing parser to {destination}")
    shutil.move(str(artifact_path), destination)

    if use_makefile and make_path:
        run_make_clean(make_path, base_dir)

    return destination


def write_revision(info_dir: Path, lang: str, revision: object) -> None:
    if not isinstance(revision, str) or not revision:
        revision_path = info_dir / f"{lang}.revision"
        if revision_path.exists():
            revision_path.unlink()
        return

    info_dir.mkdir(parents=True, exist_ok=True)
    revision_path = info_dir / f"{lang}.revision"
    revision_path.write_text(revision + "\n", encoding="utf-8")
    log_step(lang, f"Recorded revision {revision}")


def collect_installed(parser_dir: Path, suffix: str) -> set[str]:
    if not parser_dir.is_dir():
        return set()
    return {path.stem for path in parser_dir.glob(f"*{suffix}")}


def collect_revisions(info_dir: Path) -> set[str]:
    if not info_dir.is_dir():
        return set()
    return {path.stem for path in info_dir.glob("*.revision")}


def prune_extra(parser_dir: Path, info_dir: Path, suffix: str, manifest_langs: set[str]) -> None:
    installed = collect_installed(parser_dir, suffix)
    revisions = collect_revisions(info_dir)
    extras = sorted((installed | revisions) - manifest_langs)
    for lang in extras:
        lib_path = parser_dir / f"{lang}{suffix}"
        rev_path = info_dir / f"{lang}.revision"
        if lib_path.exists():
            log(f"Removing extraneous parser {lib_path}")
            lib_path.unlink()
        if rev_path.exists():
            log(f"Removing extraneous revision {rev_path}")
            rev_path.unlink()


def verify_installation(
    manifest_langs: Sequence[str],
    metadata: dict[str, dict[str, object]],
    parser_dir: Path,
    info_dir: Path,
    *,
    suffix: str,
) -> None:
    missing: list[str] = []
    revision_issues: list[str] = []

    for lang in manifest_langs:
        lib_path = parser_dir / f"{lang}{suffix}"
        if not lib_path.is_file():
            missing.append(lang)
            continue

        info = metadata.get(lang)
        if not info:
            continue
        revision = info.get("revision")
        if isinstance(revision, str) and revision:
            rev_path = info_dir / f"{lang}.revision"
            try:
                recorded = rev_path.read_text(encoding="utf-8").strip()
            except OSError:
                recorded = ""
            if recorded != revision:
                revision_issues.append(lang)

    if missing or revision_issues:
        if missing:
            sys.stderr.write("Missing Tree-sitter parsers: " + " ".join(missing) + "\n")
        if revision_issues:
            sys.stderr.write(
                "Revision metadata mismatch: " + " ".join(revision_issues) + "\n"
            )
        raise SystemExit(1)


def main(argv: Sequence[str]) -> None:
    args = parse_args(argv)

    root = repo_root()
    manifest_path = (
        Path(args.manifest)
        if args.manifest
        else root / "scripts" / "treesitter-parsers.txt"
    )
    if not manifest_path.is_file():
        raise SystemExit(f"error: manifest not found at {manifest_path}")

    log(f"Using manifest {manifest_path}")
    manifest_langs = load_manifest(manifest_path)
    if not manifest_langs:
        raise SystemExit(
            f"error: manifest {manifest_path} does not list any Tree-sitter parsers"
        )
    log(f"Manifest lists {len(manifest_langs)} parsers")

    metadata_path = root / "vendor" / "tree-sitter" / "metadata.json"
    metadata, vendor_root = load_metadata(metadata_path)

    parser_dir = root / "vendor" / "plugins" / "nvim-treesitter" / "parser"
    info_dir = root / "vendor" / "plugins" / "nvim-treesitter" / "parser-info"
    suffix = library_suffix()

    if args.check:
        verify_installation(manifest_langs, metadata, parser_dir, info_dir, suffix=suffix)
        return

    for lang in manifest_langs:
        info = metadata.get(lang)
        if not info:
            raise SystemExit(
                f"error: metadata for parser {lang} not found. "
                "Run scripts/treesitter-vendor.py to refresh vendor sources."
            )
        try:
            build_parser(lang, info, vendor_root, parser_dir, suffix=suffix)
            write_revision(info_dir, lang, info.get("revision"))
        except BuildError as exc:
            raise SystemExit(f"error: {exc}") from exc

    if args.prune:
        prune_extra(parser_dir, info_dir, suffix, set(manifest_langs))

    verify_installation(manifest_langs, metadata, parser_dir, info_dir, suffix=suffix)
    log("Parser build complete")


if __name__ == "__main__":
    main(sys.argv[1:])
