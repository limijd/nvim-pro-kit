#!/usr/bin/env python3
"""Installer for linking the Neovim configuration without touching the repo."""
from __future__ import annotations

import os
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


def config_home() -> Path:
    xdg = os.environ.get("XDG_CONFIG_HOME")
    if xdg:
        return Path(xdg).expanduser()
    return Path.home() / ".config"


def backup_existing(target: Path, source: Path) -> Path | None:
    if target.is_symlink():
        try:
            if target.resolve(strict=True) == source.resolve(strict=True):
                return None
        except FileNotFoundError:
            pass

    if not (target.exists() or target.is_symlink()):
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


def install() -> None:
    root = repo_root()
    ensure_repo_layout(root)

    source = root / "nvim"
    target = config_home() / "nvim"
    backup = backup_existing(target, source)

    if backup:
        print(f"Existing Neovim configuration moved to {backup}")

    if backup is None and target.is_symlink():
        print(f"Neovim configuration already linked at {target}")
        return

    target.parent.mkdir(parents=True, exist_ok=True)
    create_symlink(target, source)

    print(f"Linked {target} -> {source}")
    print("lazy.nvim and vendored plugins will be loaded from the repository directory.")
    print("No files inside the repository were modified.")


def main() -> int:
    try:
        install()
    except InstallError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
