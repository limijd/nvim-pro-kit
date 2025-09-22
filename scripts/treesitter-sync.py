#!/usr/bin/env python3
"""Install, update, and prune Tree-sitter parsers listed in the manifest."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path
from typing import Iterable, MutableMapping, Sequence


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install, update, and prune Tree-sitter parsers",
    )
    parser.add_argument(
        "--manifest",
        help="Override the parser manifest path.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify installed parsers match the manifest without modifying disk.",
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


def install_or_update(base_cmd: Sequence[str], env: MutableMapping[str, str], check: bool) -> None:
    if check:
        return

    lua_cmd = (
        "+lua local manifest=require('config.treesitter_manifest');"
        "local langs=manifest.languages({ silent = true });"
        "if #langs==0 then error('Tree-sitter manifest is empty') end;"
        "local vendor=require('config.treesitter_vendor');"
        "vendor.apply(langs);"
        "local install=require('nvim-treesitter.install');"
        "local runner=install.commands.TSInstallSync['run!'];"
        "for _,lang in ipairs(langs) do"
        " runner(lang);"
        "end"
    )

    run_nvim(base_cmd, env, [lua_cmd, "+qa"])


def collect_dirs(base_cmd: Sequence[str], env: MutableMapping[str, str]) -> tuple[str, str]:
    lua_cmd = (
        "+lua local configs=require('nvim-treesitter.configs');"
        "local function first(...) local t={...};return t[1];end;"
        "local parser_dir=first(configs.get_parser_install_dir());"
        "local info_dir=first(configs.get_parser_info_dir());"
        "io.write((parser_dir or '') .. '\n' .. (info_dir or ''))"
    )
    output = run_nvim(base_cmd, env, [lua_cmd, "+qa"], capture_output=True)
    lines = output.splitlines()
    parser_dir = lines[0].strip() if lines else ""
    info_dir = lines[1].strip() if len(lines) > 1 else ""
    return parser_dir, info_dir


def list_parsers(parser_dir: str) -> set[str]:
    if not parser_dir:
        return set()
    directory = Path(parser_dir)
    if not directory.is_dir():
        return set()

    names: set[str] = set()
    for pattern in ("*.so", "*.dll", "*.dylib", "*.wasm"):
        for path in directory.glob(pattern):
            names.add(path.stem.split(".")[0])
    return names


def list_revisions(info_dir: str) -> set[str]:
    if not info_dir:
        return set()
    directory = Path(info_dir)
    if not directory.is_dir():
        return set()

    return {path.stem for path in directory.glob("*.revision")}


def prune_extras(
    extra: Iterable[str],
    parser_dir: str,
    info_dir: str,
) -> None:
    parser_path = Path(parser_dir) if parser_dir else None
    info_path = Path(info_dir) if info_dir else None

    extras = sorted(set(extra))
    if not extras:
        return

    print(f"Pruning extraneous Tree-sitter parsers: {' '.join(extras)}")
    for lang in extras:
        if parser_path:
            for suffix in (".so", ".dll", ".dylib", ".wasm"):
                try:
                    (parser_path / f"{lang}{suffix}").unlink(missing_ok=True)
                except OSError:
                    pass
        if info_path:
            try:
                (info_path / f"{lang}.revision").unlink(missing_ok=True)
            except OSError:
                pass


def report(
    manifest_langs: Sequence[str],
    installed: Set[str],
    revisions: Set[str],
    *,
    check: bool,
    prune: bool,
    parser_dir: str,
    info_dir: str,
) -> None:
    manifest_set = set(manifest_langs)
    missing = [lang for lang in manifest_langs if lang not in installed]
    extra = (installed | revisions) - manifest_set

    if check:
        status = 0
        if missing:
            sys.stderr.write(
                "Missing Tree-sitter parsers: " + " ".join(missing) + "\n"
            )
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
        prune_extras(extra, parser_dir, info_dir)
    elif extra:
        print(
            "Extraneous Tree-sitter parsers detected (use --prune to remove): "
            + " ".join(sorted(extra))
        )

    if missing:
        sys.stderr.write(
            "Parsers still missing after update: " + " ".join(missing) + "\n"
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

    nvim_bin = os.environ.get("NVIM_BIN", "nvim")
    base_cmd = build_nvim_command(nvim_bin)
    env = os.environ.copy()
    env["TREESITTER_SYNC_ROOT"] = str(root)

    install_or_update(base_cmd, env, args.check)
    parser_dir, info_dir = collect_dirs(base_cmd, env)
    installed = list_parsers(parser_dir)
    revisions = list_revisions(info_dir)
    report(
        manifest_langs,
        installed,
        revisions,
        check=args.check,
        prune=args.prune,
        parser_dir=parser_dir,
        info_dir=info_dir,
    )


if __name__ == "__main__":
    main(sys.argv[1:])
