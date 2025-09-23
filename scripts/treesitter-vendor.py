#!/usr/bin/env python3
"""Vendor Tree-sitter parser sources referenced by the manifest."""
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Iterable, MutableMapping, Sequence


def log(message: str) -> None:
    """Print a status message with flushing enabled."""

    print(message, flush=True)


def progress(scope: str, index: int, total: int, message: str) -> None:
    """Print a formatted progress message for parser processing."""

    log(f"[{scope}][{index}/{total}] {message}")


def format_command(args: Sequence[str]) -> str:
    """Return a human friendly representation of a shell command."""

    return " ".join(shlex.quote(arg) for arg in args)


RUNTIME_REPOSITORY = "https://github.com/tree-sitter/tree-sitter"
RUNTIME_INCLUDE_SUBDIR = Path("lib/include/tree_sitter")
RUNTIME_FALLBACK_HEADER_DIRS = (
    Path("lib/src"),
)
RUNTIME_REQUIRED_HEADERS = (
    "api.h",
    "parser.h",
    "alloc.h",
    "array.h",
)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Snapshot Tree-sitter parser sources into vendor/tree-sitter",
    )
    parser.add_argument(
        "--manifest",
        help="Override the parser manifest path.",
    )
    parser.add_argument(
        "--output",
        default="vendor/tree-sitter",
        help="Directory (relative to repo root) where sources are stored.",
    )
    parser.add_argument(
        "--nvim",
        default=os.environ.get("NVIM_BIN", "nvim"),
        help="Neovim binary to execute (default: %(default)s)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify vendored sources without touching disk.",
    )
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


def build_nvim_command(nvim_bin: str) -> list[str]:
    runtime_setup = (
        "+lua (function(root) if root ~= '' then local paths = {'/vendor/plugins/plenary.nvim','/vendor/plugins/nvim-treesitter','/nvim'} for _, suffix in ipairs(paths) do vim.opt.runtimepath:prepend(root .. suffix) end end end)(vim.env.TREESITTER_SYNC_ROOT or '')"
    )
    return [
        nvim_bin,
        "--headless",
        "--clean",
        runtime_setup,
        "+runtime plugin/plenary.vim",
        "+runtime plugin/nvim-treesitter.lua",
    ]


def run_nvim(
    base_cmd: Sequence[str],
    env: MutableMapping[str, str],
    extra_args: Iterable[str],
    *,
    capture_output: bool = False,
) -> str:
    stdout = subprocess.PIPE if capture_output else None
    stderr = subprocess.STDOUT if capture_output else None
    full_cmd = [*base_cmd, *extra_args]
    log(f"[vendor] Running: {format_command(full_cmd)}")
    try:
        result = subprocess.run(
            full_cmd,
            env=env,
            check=True,
            text=True,
            stdout=stdout,
            stderr=stderr,
        )
    except subprocess.CalledProcessError as exc:
        if capture_output and exc.stdout:
            sys.stderr.write(exc.stdout)
        raise SystemExit("error: Neovim command failed") from exc
    return result.stdout or ""


def gather_install_info(
    base_cmd: Sequence[str], env: MutableMapping[str, str]
) -> dict[str, dict[str, object]]:
    log("[vendor] Gathering parser metadata from Neovim")
    lua_cmd = (
        "+lua local manifest=require('config.treesitter_manifest');"
        "local langs=manifest.languages({ silent = true });"
        "local configs=require('nvim-treesitter.parsers').get_parser_configs();"
        "local data={};"
        "for _,lang in ipairs(langs) do"
        " local cfg=configs[lang];"
        " if cfg and cfg.install_info then"
        "  local info=vim.deepcopy(cfg.install_info);"
        "  info.files=info.files or {};"
        "  data[lang]=info;"
        " end "
        "end;"
        "io.write(vim.fn.json_encode(data))"
    )
    output = run_nvim(base_cmd, env, [lua_cmd, "+qa"], capture_output=True)
    if not output:
        return {}
    try:
        decoded = json.loads(output)
    except json.JSONDecodeError as exc:
        preview = output.strip().splitlines()
        preview = preview[0] if preview else ''
        raise SystemExit("error: failed to decode install metadata: %s (first line: %r)" % (exc, preview)) from exc
    if not isinstance(decoded, dict):
        raise SystemExit("error: unexpected install metadata format")
    return decoded


def git_clone(url: str, dest: Path, branch: str | None, revision: str | None) -> None:
    clone_cmd = ["git", "clone", url, str(dest)]
    if branch:
        clone_cmd.extend(["--branch", branch])
    log(f"[vendor] Running: {format_command(clone_cmd)}")
    try:
        subprocess.run(clone_cmd, check=True)
    except subprocess.CalledProcessError as exc:
        raise SystemExit(f"error: failed to clone {url}") from exc

    if revision:
        try:
            checkout_cmd = ["git", "checkout", revision]
            log(f"[vendor] Running: (cwd={dest}) {format_command(checkout_cmd)}")
            subprocess.run(checkout_cmd, cwd=dest, check=True)
        except subprocess.CalledProcessError as exc:
            raise SystemExit(
                f"error: failed to check out revision {revision} in {url}"
            ) from exc


def copy_runtime_headers(runtime_dir: Path, destination: Path) -> None:
    if not runtime_dir.is_dir():
        raise SystemExit(
            f"error: vendored Tree-sitter runtime headers missing at {runtime_dir}"
        )

    target = destination / "tree_sitter"
    target.parent.mkdir(parents=True, exist_ok=True)

    log(f"[vendor] Mirroring runtime headers into {destination}")
    if not target.exists():
        try:
            shutil.copytree(runtime_dir, target)
        except OSError as exc:
            raise SystemExit(
                "error: failed to copy Tree-sitter runtime headers into "
                f"{target}: {exc}"
            ) from exc
        return

    for source in runtime_dir.rglob("*"):
        relative = source.relative_to(runtime_dir)
        destination_path = target / relative
        if source.is_dir():
            destination_path.mkdir(parents=True, exist_ok=True)
            continue
        if destination_path.exists():
            continue
        destination_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            shutil.copy2(source, destination_path)
        except OSError as exc:
            raise SystemExit(
                "error: failed to copy Tree-sitter runtime header "
                f"{relative} into {target}: {exc}"
            ) from exc


def vendor_runtime(output_dir: Path, *, check: bool) -> Path:
    runtime_dir = output_dir / "tree_sitter"
    metadata_path = output_dir / "runtime.json"

    output_dir.mkdir(parents=True, exist_ok=True)

    if check:
        log("[vendor] Verifying vendored Tree-sitter runtime")
        if not runtime_dir.is_dir():
            raise SystemExit(
                "error: vendored Tree-sitter runtime headers are missing"
            )
        missing = [
            header
            for header in RUNTIME_REQUIRED_HEADERS
            if not (runtime_dir / header).is_file()
        ]
        if missing:
            joined = ", ".join(missing)
            raise SystemExit(
                "error: vendored Tree-sitter runtime headers missing required files: "
                f"{joined}"
            )
        if not metadata_path.is_file():
            raise SystemExit("error: runtime metadata not found")
        return runtime_dir

    log("[vendor] Updating vendored Tree-sitter runtime headers")
    with tempfile.TemporaryDirectory() as tmpdir:
        repo_dest = Path(tmpdir) / "runtime"
        git_clone(RUNTIME_REPOSITORY, repo_dest, None, None)

        include_dir = repo_dest / RUNTIME_INCLUDE_SUBDIR
        if not include_dir.is_dir():
            raise SystemExit(
                "error: Tree-sitter repository layout changed, include directory not found"
            )

        if runtime_dir.exists():
            shutil.rmtree(runtime_dir)
        shutil.copytree(include_dir, runtime_dir)

        for rel_dir in RUNTIME_FALLBACK_HEADER_DIRS:
            source_dir = repo_dest / rel_dir
            if not source_dir.is_dir():
                continue
            for path in source_dir.rglob("*.h"):
                relative = path.relative_to(source_dir)
                destination = runtime_dir / relative
                if destination.exists():
                    continue
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(path, destination)

        rev_cmd = ["git", "rev-parse", "HEAD"]
        log(
            f"[vendor] Running: (cwd={repo_dest}) {format_command(rev_cmd)}"
        )
        try:
            result = subprocess.check_output(rev_cmd, cwd=repo_dest, text=True)
        except subprocess.CalledProcessError as exc:
            raise SystemExit("error: failed to determine Tree-sitter runtime revision") from exc

    revision = result.strip()

    metadata = {
        "url": RUNTIME_REPOSITORY,
        "revision": revision,
    }
    tmp_path = metadata_path.with_suffix(".tmp")
    tmp_path.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp_path.replace(metadata_path)

    return runtime_dir


def copy_repo(
    lang: str,
    info: dict[str, object],
    repo_path: Path,
    dest_root: Path,
    runtime_dir: Path | None,
) -> None:
    files = info.get("files")
    if not isinstance(files, list) or not all(isinstance(f, str) for f in files):
        raise SystemExit(f"error: install info for {lang} does not list source files")

    location = info.get("location")
    location_path = Path(location) if isinstance(location, str) and location else None

    source_base = repo_path / location_path if location_path else repo_path
    if not source_base.is_dir():
        raise SystemExit(
            "error: expected directory for parser {lang} at {base} is missing".format(
                lang=lang, base=source_base
            )
        )

    missing = []
    for rel in files:
        rel_path = Path(rel)
        source = source_base / rel_path
        if not source.is_file():
            missing.append(rel_path.as_posix())
    if missing:
        joined = ", ".join(missing)
        raise SystemExit(
            f"error: repository for {lang} missing expected files: {joined}"
        )

    dest_lang_dir = dest_root / lang
    if dest_lang_dir.exists():
        log(f"[vendor] {lang}: removing previous snapshot at {dest_lang_dir}")
        shutil.rmtree(dest_lang_dir)
    log(f"[vendor] {lang}: copying sources into {dest_lang_dir}")
    try:
        shutil.copytree(
            repo_path,
            dest_lang_dir,
            ignore=shutil.ignore_patterns(".git"),
        )
    except OSError as exc:
        raise SystemExit(
            f"error: failed to copy repository for {lang} into {dest_lang_dir}: {exc}"
        ) from exc

    base_dir = dest_lang_dir / location_path if location_path else dest_lang_dir

    if runtime_dir is not None:
        src_dir = base_dir / "src"
        if src_dir.is_dir():
            copy_runtime_headers(runtime_dir, src_dir)


def validate_repo(
    lang: str,
    info: dict[str, object],
    dest_lang_dir: Path,
    output_dir: Path,
    runtime_dir: Path | None,
) -> None:
    if not dest_lang_dir.is_dir():
        raise SystemExit(
            f"error: vendored parser directory missing for {lang} at {dest_lang_dir}"
        )

    location = info.get("location")
    location_path = Path(location) if isinstance(location, str) and location else None
    base_dir = dest_lang_dir / location_path if location_path else dest_lang_dir
    if not base_dir.is_dir():
        raise SystemExit(
            f"error: vendored parser for {lang} missing expected location directory"
        )

    files = info.get("files") or []
    missing: list[str] = []
    for rel in files:
        rel_path = Path(rel)
        file_path = base_dir / rel_path
        if not file_path.is_file():
            try:
                missing.append(str(file_path.relative_to(output_dir)))
            except ValueError:
                missing.append(str(file_path))

    if runtime_dir is not None:
        src_dir = base_dir / "src"
        if src_dir.is_dir():
            runtime_base = src_dir / "tree_sitter"
            for header in RUNTIME_REQUIRED_HEADERS:
                header_path = runtime_base / header
                if not header_path.is_file():
                    try:
                        missing.append(str(header_path.relative_to(output_dir)))
                    except ValueError:
                        missing.append(str(header_path))

    if missing:
        raise SystemExit(
            "error: vendored parser sources missing required files for "
            f"{lang}: {' '.join(sorted(set(missing)))}"
        )


def vendor_parsers(
    languages: Sequence[str],
    install_info: dict[str, dict[str, object]],
    output_dir: Path,
    runtime_dir: Path | None,
    *,
    check: bool,
) -> dict[str, dict[str, object]]:
    output_dir.mkdir(parents=True, exist_ok=True)
    metadata: dict[str, dict[str, object]] = {}
    existing_metadata_path = output_dir / "metadata.json"
    existing_metadata: dict[str, dict[str, object]] = {}
    if existing_metadata_path.is_file():
        try:
            existing_metadata = json.loads(
                existing_metadata_path.read_text(encoding="utf-8")
            )
        except json.JSONDecodeError as exc:
            raise SystemExit(
                f"error: failed to decode existing metadata at {existing_metadata_path}: {exc}"
            ) from exc

    total = len(languages)
    for index, lang in enumerate(languages, 1):
        if index > 1:
            log("")
        info = install_info.get(lang)
        if not info:
            raise SystemExit(f"error: missing install info for parser {lang}")
        url = info.get("url")
        if not isinstance(url, str):
            raise SystemExit(f"error: parser {lang} does not define a download URL")

        branch = info.get("branch") if isinstance(info.get("branch"), str) else None
        revision = info.get("revision") if isinstance(info.get("revision"), str) else None

        dest_lang_dir = output_dir / lang
        if check:
            progress(
                "vendor",
                index,
                total,
                f"Verifying tree-sitter {lang} parser snapshot...",
            )
            validate_repo(lang, info, dest_lang_dir, output_dir, runtime_dir)
            if lang in existing_metadata:
                metadata[lang] = existing_metadata[lang]
            else:
                metadata[lang] = {
                    "url": url,
                    "branch": branch,
                    "revision": revision,
                    "files": info.get("files", []),
                    "location": info.get("location"),
                    "generate_requires_npm": info.get("generate_requires_npm"),
                    "requires_generate_from_grammar": info.get(
                        "requires_generate_from_grammar"
                    ),
                    "use_makefile": info.get("use_makefile"),
                    "cxx_standard": info.get("cxx_standard"),
                }
            continue

        progress(
            "vendor",
            index,
            total,
            f"Pulling tree-sitter {lang} parser sources...",
        )
        log(f"[vendor] {lang}: fetching sources from {url}")
        with tempfile.TemporaryDirectory() as tmpdir:
            repo_dest = Path(tmpdir) / "repo"
            git_clone(url, repo_dest, branch, revision)
            rev_cmd = ["git", "rev-parse", "HEAD"]
            log(
                f"[vendor] {lang}: determining revision with {format_command(rev_cmd)}"
            )
            try:
                result = subprocess.check_output(rev_cmd, cwd=repo_dest, text=True)
            except subprocess.CalledProcessError as exc:
                raise SystemExit(
                    f"error: failed to determine HEAD revision for {lang}"
                ) from exc
            resolved_revision = result.strip()

            copy_repo(lang, info, repo_dest, output_dir, runtime_dir)
            validate_repo(lang, info, dest_lang_dir, output_dir, runtime_dir)
            log(f"[vendor] {lang}: snapshot captured at {resolved_revision}")

        metadata[lang] = {
            "url": url,
            "branch": branch,
            "revision": revision or resolved_revision,
            "files": info.get("files", []),
            "location": info.get("location"),
            "generate_requires_npm": info.get("generate_requires_npm"),
            "requires_generate_from_grammar": info.get("requires_generate_from_grammar"),
            "use_makefile": info.get("use_makefile"),
            "cxx_standard": info.get("cxx_standard"),
        }

    return metadata


def write_metadata(path: Path, data: dict[str, dict[str, object]]) -> None:
    tmp_path = path.with_suffix(".tmp")
    text = json.dumps(data, indent=2, sort_keys=True)
    tmp_path.write_text(text + "\n", encoding="utf-8")
    tmp_path.replace(path)


def prune_languages(output_dir: Path, languages: Sequence[str]) -> None:
    if not output_dir.is_dir():
        return

    keep = set(languages)
    keep.add("tree_sitter")

    for path in output_dir.iterdir():
        if path.is_dir() and path.name not in keep:
            log(f"[vendor] Removing obsolete parser snapshot {path}")
            shutil.rmtree(path)


def stage_paths(root: Path, paths: Sequence[Path]) -> None:
    if not paths:
        return

    rel_paths: list[str] = []
    for path in paths:
        try:
            rel_paths.append(str(path.relative_to(root)))
        except ValueError:
            rel_paths.append(str(path))

    cmd = ["git", "-C", str(root), "add", "-A", *rel_paths]
    log(f"[vendor] Running: {format_command(cmd)}")
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as exc:
        joined = " ".join(rel_paths)
        raise SystemExit(f"error: failed to stage updated vendor sources ({joined})") from exc


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

    manifest_langs = load_manifest(manifest_path)
    if not manifest_langs:
        raise SystemExit(
            f"error: manifest {manifest_path} does not list any Tree-sitter parsers"
        )

    log(f"[vendor] Loaded manifest from {manifest_path} ({len(manifest_langs)} languages)")

    base_cmd = build_nvim_command(args.nvim)
    env = os.environ.copy()
    env["TREESITTER_SYNC_ROOT"] = str(root)

    install_info = gather_install_info(base_cmd, env)

    output_dir = root / args.output
    runtime_dir = vendor_runtime(output_dir, check=args.check)
    metadata = vendor_parsers(
        manifest_langs,
        install_info,
        output_dir,
        runtime_dir,
        check=args.check,
    )

    if not args.check:
        prune_languages(output_dir, manifest_langs)
        metadata_path = output_dir / "metadata.json"
        write_metadata(metadata_path, metadata)
        stage_paths(root, [output_dir, metadata_path])


if __name__ == "__main__":
    main(sys.argv[1:])
