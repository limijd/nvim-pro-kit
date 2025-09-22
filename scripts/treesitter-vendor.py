#!/usr/bin/env python3
"""Vendor Tree-sitter parser sources referenced by the manifest."""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Iterable, MutableMapping, Sequence


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
    try:
        result = subprocess.run(
            [*base_cmd, *extra_args],
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


def ensure_clean_dir(path: Path) -> None:
    if path.is_dir():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def git_clone(url: str, dest: Path, branch: str | None, revision: str | None) -> None:
    clone_cmd = ["git", "clone", url, str(dest)]
    if branch:
        clone_cmd.extend(["--branch", branch])
    try:
        subprocess.run(clone_cmd, check=True)
    except subprocess.CalledProcessError as exc:
        raise SystemExit(f"error: failed to clone {url}") from exc

    if revision:
        try:
            subprocess.run(["git", "checkout", revision], cwd=dest, check=True)
        except subprocess.CalledProcessError as exc:
            raise SystemExit(
                f"error: failed to check out revision {revision} in {url}"
            ) from exc


def copy_sources(
    lang: str,
    info: dict[str, object],
    repo_path: Path,
    dest_root: Path,
) -> None:
    files = info.get("files")
    if not isinstance(files, list) or not all(isinstance(f, str) for f in files):
        raise SystemExit(f"error: install info for {lang} does not list source files")

    location = info.get("location")
    location_path = Path(location) if isinstance(location, str) and location else None
    source_root = repo_path / location_path if location_path else repo_path

    dest_base = dest_root / lang
    if location_path:
        dest_base = dest_base / location_path

    ensure_clean_dir(dest_base)

    for rel in files:
        rel_path = Path(rel)
        source = source_root / rel_path
        if not source.is_file():
            raise SystemExit(
                f"error: expected source file {source} for {lang} is missing"
            )
        destination = dest_base / rel_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def vendor_parsers(
    languages: Sequence[str],
    install_info: dict[str, dict[str, object]],
    output_dir: Path,
    *,
    check: bool,
) -> dict[str, dict[str, object]]:
    output_dir.mkdir(parents=True, exist_ok=True)
    metadata: dict[str, dict[str, object]] = {}

    for lang in languages:
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
            required_files = info.get("files") or []
            missing = []
            location = info.get("location")
            base = dest_lang_dir / location if isinstance(location, str) and location else dest_lang_dir
            for rel in required_files:
                file_path = base / Path(rel)
                if not file_path.is_file():
                    missing.append(str(file_path.relative_to(output_dir)))
            if missing:
                raise SystemExit(
                    "error: vendored parser sources missing required files for "
                    f"{lang}: {' '.join(missing)}"
                )
            continue

        with tempfile.TemporaryDirectory() as tmpdir:
            repo_dest = Path(tmpdir) / "repo"
            git_clone(url, repo_dest, branch, revision)
            try:
                result = subprocess.check_output(
                    ["git", "rev-parse", "HEAD"], cwd=repo_dest, text=True
                )
            except subprocess.CalledProcessError as exc:
                raise SystemExit(
                    f"error: failed to determine HEAD revision for {lang}"
                ) from exc
            resolved_revision = result.strip()

            copy_sources(lang, info, repo_dest, output_dir)

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

    base_cmd = build_nvim_command(args.nvim)
    env = os.environ.copy()
    env["TREESITTER_SYNC_ROOT"] = str(root)

    install_info = gather_install_info(base_cmd, env)

    output_dir = root / args.output
    metadata = vendor_parsers(
        manifest_langs,
        install_info,
        output_dir,
        check=args.check,
    )

    if not args.check:
        write_metadata(output_dir / "metadata.json", metadata)


if __name__ == "__main__":
    main(sys.argv[1:])
