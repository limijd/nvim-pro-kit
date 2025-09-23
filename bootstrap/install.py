#!/usr/bin/env python3
"""Bootstrap installer for nvim-pro-kit.

This script links or copies the repository's Neovim configuration into the
user's config directory while ensuring vendored plugins remain available.
"""
from __future__ import annotations

import argparse
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import Iterable


class InstallError(RuntimeError):
    """Raised when the installation cannot be completed."""


def parse_args(argv: Iterable[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Install the vendored nvim-pro-kit configuration without requiring "
            "network access. By default the configuration is linked into "
            "$XDG_CONFIG_HOME/nvim (or ~/.config/nvim)."
        )
    )
    parser.add_argument(
        "--copy",
        action="store_true",
        help="copy files instead of creating symbolic links",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="overwrite existing targets instead of creating timestamped backups",
    )
    parser.add_argument(
        "--target",
        type=Path,
        help="install into the specified directory instead of the default",
    )
    return parser.parse_args(argv)


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def path_exists(path: Path) -> bool:
    return path.exists() or path.is_symlink()


def remove_path(path: Path) -> None:
    if not path_exists(path):
        return
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()


def backup_path(path: Path, *, label: str, force: bool) -> None:
    if not path_exists(path):
        return
    if force:
        remove_path(path)
        return

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    backup = path.with_name(f"{path.name}.backup.{timestamp}")
    counter = 1
    while path_exists(backup):
        backup = path.with_name(f"{path.name}.backup.{timestamp}.{counter}")
        counter += 1

    print(f"Existing {label} detected. Moving it to {backup}")
    path.rename(backup)


def validate_layout(nvim_root: Path, vendor_root: Path) -> None:
    if not nvim_root.is_dir():
        raise InstallError(
            "Repository is missing the nvim/ directory expected to contain init.lua."
        )

    plugins_root = vendor_root / "plugins"
    if not plugins_root.is_dir():
        raise InstallError("Repository is missing the vendor/ directory containing plugins.")

    lazy_dir = plugins_root / "lazy.nvim"
    if not lazy_dir.is_dir():
        raise InstallError(
            "lazy.nvim vendor directory is missing; installation cannot continue."
        )


def copy_tree(source: Path, target: Path) -> None:
    shutil.copytree(source, target, symlinks=True)


def install(copy_mode: bool, force: bool, target: Path | None) -> None:
    root = repo_root()
    nvim_root = root / "nvim"
    vendor_root = root / "vendor"

    validate_layout(nvim_root, vendor_root)

    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    default_target = config_home / "nvim"
    target = (target or default_target).expanduser()
    target = target.resolve(strict=False)
    backup_path(target, label="Neovim config", force=force)

    target.parent.mkdir(parents=True, exist_ok=True)

    if copy_mode:
        vendor_target = target / "vendor"
        backup_path(vendor_target, label="vendored plugins", force=force)

        copy_tree(nvim_root, target)
        copy_tree(vendor_root, vendor_target)

        print(f"Neovim configuration copied to {target}")
        print(f"Vendored plugins copied to {vendor_target}")
    else:
        target.symlink_to(nvim_root, target_is_directory=True)

        print(f"Neovim configuration linked at {target} -> {nvim_root}")
        print("Vendored plugins will be loaded from the repository's vendor directory")
    print()
    print("You can now start Neovim without an internet connection using: nvim")
    print(
        "If you move this installation, set NVIM_PRO_KIT_ROOT to the repository "
        "path so helper scripts can locate the vendor directory."
    )


def main(argv: Iterable[str]) -> int:
    try:
        args = parse_args(argv)
        install(args.copy, args.force, args.target)
        return 0
    except InstallError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
