#!/usr/bin/env python3
"""Install the Neovim configuration without requiring network access."""
from __future__ import annotations

import argparse
import datetime as _dt
import os
import shutil
import sys
from pathlib import Path


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="bootstrap/install.py",
        description=(
            "Install this Neovim configuration into your system without requiring "
            "network access. By default the script creates a symbolic link at "
            "$XDG_CONFIG_HOME/nvim (or ~/.config/nvim) pointing to the repository."
        ),
    )
    parser.add_argument(
        "--copy",
        dest="mode",
        action="store_const",
        const="copy",
        default="link",
        help="Copy files instead of creating a symlink",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the target directory instead of creating a backup",
    )
    parser.add_argument(
        "--target",
        metavar="DIR",
        help="Install to DIR instead of the default",
    )
    return parser.parse_args(argv)


def remove_path(path: Path) -> None:
    try:
        if path.is_symlink() or path.is_file():
            path.unlink()
        elif path.is_dir():
            shutil.rmtree(path)
        else:
            path.unlink(missing_ok=True)  # type: ignore[attr-defined]
    except FileNotFoundError:
        return


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    repo_root = Path(__file__).resolve().parent.parent
    nvim_root = repo_root / "nvim"
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    target = Path(args.target) if args.target else config_home / "nvim"

    lazy_vendor = repo_root / "vendor" / "plugins" / "lazy.nvim"
    if not lazy_vendor.is_dir():
        print(
            "lazy.nvim vendor directory is missing; installation cannot continue.",
            file=sys.stderr,
        )
        return 1

    if not nvim_root.is_dir():
        print(
            "Repository is missing the nvim/ directory expected to contain init.lua",
            file=sys.stderr,
        )
        return 1

    if target.exists() or target.is_symlink():
        if args.force:
            remove_path(target)
        else:
            timestamp = _dt.datetime.now().strftime("%Y%m%d%H%M%S")
            backup = target.with_name(f"{target.name}.backup.{timestamp}")
            print(f"Existing Neovim config detected. Moving it to {backup}")
            target.rename(backup)

    target.parent.mkdir(parents=True, exist_ok=True)

    if args.mode == "link":
        target.symlink_to(nvim_root)
    else:
        shutil.copytree(nvim_root, target, symlinks=True, ignore=shutil.ignore_patterns(".git"))

    print(f"Neovim configuration installed to {target}")
    print("You can now start Neovim without an internet connection using: nvim")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
