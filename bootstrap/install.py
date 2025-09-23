#!/usr/bin/env python3
"""Installer for linking the Neovim configuration without touching the repo."""
from __future__ import annotations

import argparse
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path


class InstallError(RuntimeError):
    """Raised when installation requirements are not met."""


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def ensure_repo_layout(root: Path) -> None:
    nvim_dir = root / "nvim"
    init_file = nvim_dir / "init.lua"
    lazy_dir = root / "vendor" / "plugins" / "lazy.nvim"

    if not init_file.is_file():
        raise InstallError("init.lua was not found inside the repository's nvim directory")
    if not lazy_dir.is_dir():
        raise InstallError("lazy.nvim is missing from vendor/plugins; cannot continue")


def config_home(override: Path | None = None) -> Path:
    if override is not None:
        return override.expanduser()

    xdg = os.environ.get("XDG_CONFIG_HOME")
    if xdg:
        return Path(xdg).expanduser()
    return Path.home() / ".config"


def link_points_to(target: Path, source: Path) -> bool:
    if not target.is_symlink():
        return False
    try:
        return target.resolve(strict=True) == source.resolve(strict=True)
    except FileNotFoundError:
        return False


def remove_existing(target: Path) -> None:
    if target.is_symlink() or target.is_file():
        target.unlink()
    elif target.is_dir():
        shutil.rmtree(target)
    else:
        target.unlink(missing_ok=True)


def backup_existing(target: Path, create_backup: bool) -> Path | None:
    if not (target.exists() or target.is_symlink()):
        return None

    if not create_backup:
        remove_existing(target)
        return None

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    backup = target.with_name(f"{target.name}.backup.{timestamp}")
    target.rename(backup)
    return backup


def create_symlink(target: Path, source: Path) -> None:
    if target.exists() or target.is_symlink():
        raise InstallError(
            f"Installation target {target} already exists. This should have been backed up first."
        )

    target.symlink_to(source, target_is_directory=True)


def install(
    config_override: Path | None = None,
    *,
    create_backup: bool = True,
    dry_run: bool = False,
) -> None:
    root = repo_root()
    ensure_repo_layout(root)

    source = root / "nvim"
    config_root = config_home(config_override)
    target = config_root / "nvim"

    if link_points_to(target, source):
        message = f"Neovim configuration already linked at {target}"
        print(message if not dry_run else f"No changes required: {message}")
        return

    existing = target.exists() or target.is_symlink()
    if dry_run:
        if existing:
            if create_backup:
                print(
                    f"Would move existing Neovim configuration at {target} to a timestamped backup"
                )
            else:
                print(f"Would remove existing Neovim configuration at {target}")
        print(f"Would link {target} -> {source}")
        return

    backup = backup_existing(target, create_backup)

    if backup:
        print(f"Existing Neovim configuration moved to {backup}")

    target.parent.mkdir(parents=True, exist_ok=True)
    create_symlink(target, source)

    print(f"Linked {target} -> {source}")
    print("lazy.nvim and vendored plugins will be loaded from the repository directory.")
    print("No files inside the repository were modified.")


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config-home",
        type=Path,
        default=None,
        help="Override the target XDG configuration directory (defaults to $XDG_CONFIG_HOME or ~/.config)",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Remove any existing Neovim configuration instead of creating a timestamped backup",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show the operations that would be performed without modifying the filesystem",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        install(
            args.config_home,
            create_backup=not args.no_backup,
            dry_run=args.dry_run,
        )
    except InstallError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
