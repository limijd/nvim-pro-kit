#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
vendor_update.py — One-stop git-subtree manager for vendored Neovim plugins.

This tool keeps `vendor/plugins/` in sync with a single source of truth:
`scripts/plugins-list.txt` (three columns: URL NAME REF; '#' comments allowed).

Default behavior:
  • If vendor/plugins/<NAME> is missing  →  git subtree add (snapshot import)
  • If it exists                         →  git subtree pull (update snapshot)
  • Nothing is deleted unless you pass --prune

Typical usage:
  # Preview actions without changing anything
  scripts/vendor_update.py --dry-run

  # Add missing and update existing, then commit
  scripts/vendor_update.py --commit

  # Only act on specific plugins
  scripts/vendor_update.py --only telescope.nvim nvim-cmp --commit

  # Also remove directories not listed in plugins-list.txt
  scripts/vendor_update.py --prune --commit

  # Keep full upstream history (not recommended for large repos)
  scripts/vendor_update.py --no-squash --commit

  # Commit and push after a successful sync
  scripts/vendor_update.py --commit --push

Assumptions & Notes:
  • Uses git-subtree (not submodules). No remote metadata is persisted;
    we re-specify <URL> and <REF> for add/pull actions each time.
  • --squash (default) keeps your repo history compact and readable.
  • We refuse to operate on a dirty working tree unless --allow-dirty is set.
  • Never place a nested .git inside vendor/plugins/<NAME>; this script expects
    plain directories created by git-subtree, not submodules.

Author: You
License: MIT (or your choice)
"""
from __future__ import annotations

import argparse
import datetime
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple


# ---------- Configuration Defaults ----------
VENDOR_DIR = Path("vendor/plugins")
LIST_FILE_DEFAULT = Path("scripts/plugins-list.txt")


# ---------- Small helpers ----------
def _run(cmd: List[str], cwd: Path, dry: bool) -> None:
    """Pretty-print then execute a command (unless dry-run)."""
    print(" ", "$", " ".join(shlex.quote(x) for x in cmd))
    if not dry:
        subprocess.run(cmd, cwd=cwd, check=True)


def _repo_root() -> Path:
    out = subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True
    ).strip()
    return Path(out)


def _require_clean_tree(allow_dirty: bool, root: Path) -> None:
    if allow_dirty:
        return
    rc1 = subprocess.run(["git", "diff", "--quiet"], cwd=root).returncode
    rc2 = subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=root).returncode
    if rc1 != 0 or rc2 != 0:
        sys.exit("ERROR: Working tree not clean. Commit/stash or use --allow-dirty.")


def _parse_list(list_file: Path) -> List[Tuple[str, str, str]]:
    """Return [(url, name, ref), ...] from a 3-column txt file; '#' comments allowed."""
    if not list_file.exists():
        sys.exit(f"ERROR: list file not found: {list_file}")
    lines = list_file.read_text(encoding="utf-8").splitlines()

    items: List[Tuple[str, str, str]] = []
    seen_names: Set[str] = set()

    for idx, raw in enumerate(lines, start=1):
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        parts = s.split()
        if len(parts) < 3:
            sys.exit(f"ERROR: Bad line {idx} in {list_file} (need 3 columns): {raw!r}")
        url, name, ref = parts[0], parts[1], parts[2]
        if name in seen_names:
            sys.exit(f"ERROR: Duplicate NAME '{name}' in {list_file} (line {idx}).")
        seen_names.add(name)
        items.append((url, name, ref))
    return items


# ---------- High-level actions ----------
def _subtree_add(
    root: Path, url: str, name: str, ref: str, squash: bool, dry: bool
) -> None:
    path = VENDOR_DIR / name
    print(f"➕ add    {name:<28} ({ref})")
    cmd = ["git", "subtree", "add", "--prefix", str(path), url, ref]
    if squash:
        cmd.append("--squash")
    _run(cmd, cwd=root, dry=dry)


def _subtree_pull(
    root: Path, url: str, name: str, ref: str, squash: bool, dry: bool
) -> None:
    path = VENDOR_DIR / name
    print(f"🔄 update {name:<28} ({ref})")
    if not dry:
        # Warm up fetch (subtree pull will fetch too, but this improves reliability).
        subprocess.run(["git", "fetch", url, ref, "--no-tags", "--depth=1"], cwd=root)
    cmd = ["git", "subtree", "pull", "--prefix", str(path), url, ref]
    if squash:
        cmd.append("--squash")
    _run(cmd, cwd=root, dry=dry)


def _git_rm_dir(root: Path, name: str, dry: bool) -> None:
    path = VENDOR_DIR / name
    print(f"🗑️  remove {name}")
    _run(["git", "rm", "-r", str(path)], cwd=root, dry=dry)


# ---------- CLI ----------
def build_parser() -> argparse.ArgumentParser:
    epilog = (
        "plugins-list.txt format (whitespace-separated):\n"
        "  URL                                   NAME                        REF\n"
        "  https://github.com/folke/lazy.nvim    lazy.nvim                   stable\n"
        "  https://github.com/nvim-lua/plenary.nvim plenary.nvim            master\n"
        "\n"
        "NAME becomes the folder under vendor/plugins/NAME.\n"
        "REF can be a branch (main/master), a tag (v1.2.3), or a commit SHA.\n"
    )
    p = argparse.ArgumentParser(
        description="Add/update vendored plugins via git-subtree (optional prune).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=epilog,
    )
    p.add_argument(
        "--list-file",
        default=str(LIST_FILE_DEFAULT),
        help="Path to plugins list (default: scripts/plugins-list.txt)",
    )
    p.add_argument(
        "--only", nargs="+", default=[], help="Only act on specific plugin NAMEs"
    )
    p.add_argument(
        "--add-only", action="store_true", help="Only add missing (skip updates)"
    )
    p.add_argument(
        "--pull-only", action="store_true", help="Only update existing (skip adds)"
    )
    p.add_argument(
        "--no-squash",
        action="store_true",
        help="Keep full upstream history (default is --squash)",
    )
    p.add_argument(
        "--dry-run", action="store_true", help="Show actions without executing them"
    )
    p.add_argument(
        "--commit", action="store_true", help="Auto-commit changes when done"
    )
    p.add_argument(
        "--push", action="store_true", help="Push after --commit (requires --commit)"
    )
    p.add_argument(
        "--prune",
        action="store_true",
        help="Also remove vendor/plugins/* not listed in --list-file",
    )
    p.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Skip clean working tree check (use with caution)",
    )
    p.add_argument("--list", action="store_true", help="Print parsed plugins and exit")
    return p


def main() -> None:
    args = build_parser().parse_args()

    root = _repo_root()
    _require_clean_tree(args.allow_dirty, root)

    if args.push and not args.commit:
        sys.exit("ERROR: --push requires --commit")

    list_file = root / Path(args.list_file)
    items = _parse_list(list_file)

    if args.list:
        print(f"Parsed {len(items)} plugin(s) from {list_file}:")
        for url, name, ref in items:
            print(f"  - {name:<28} {ref:<16}  {url}")
        return

    (root / VENDOR_DIR).mkdir(parents=True, exist_ok=True)

    want: Dict[str, Tuple[str, str]] = {name: (url, ref) for (url, name, ref) in items}
    only: Set[str] = set(args.only)
    squash = not args.no_squash

    existing: Set[str] = set(
        p.name for p in (root / VENDOR_DIR).glob("*") if p.is_dir()
    )

    added = updated = removed = skipped = 0

    # Add / Update the listed plugins
    for name, (url, ref) in want.items():
        if only and name not in only:
            skipped += 1
            continue
        path = root / VENDOR_DIR / name

        # Sanity guard against submodules
        if path.exists() and (path / ".git").exists():
            sys.exit(
                f"ERROR: {path} contains a nested .git (submodule?). "
                "This tool expects plain directories created by git-subtree."
            )

        if path.exists():
            if args.add_only:
                print(f"⏭  exists, skip add: {name}")
                skipped += 1
            else:
                _subtree_pull(root, url, name, ref, squash, args.dry_run)
                updated += 1
        else:
            if args.pull_only:
                print(f"⏭  missing, skip pull: {name}")
                skipped += 1
            else:
                _subtree_add(root, url, name, ref, squash, args.dry_run)
                added += 1

    # Optional prune
    if args.prune:
        to_remove = existing - set(want.keys())
        if only:  # prune only inside the targeted subset for safety
            to_remove &= only
        for name in sorted(to_remove):
            if (root / VENDOR_DIR / name / ".git").exists():
                sys.exit(
                    f"ERROR: {VENDOR_DIR}/{name} has a nested .git (submodule?). Not removing."
                )
            _git_rm_dir(root, name, args.dry_run)
            removed += 1

    print(
        f"✅ Summary: added={added}  updated={updated}  removed={removed}  skipped={skipped}"
    )

    # Auto-commit & optional push
    if args.commit and not args.dry_run and (added or updated or removed):
        msg = f"chore: vendor plugins sync {datetime.date.today().isoformat()}"
        _run(["git", "commit", "-m", msg], cwd=root, dry=False)
        print(f"💾 Committed: {msg}")
        if args.push:
            _run(["git", "push"], cwd=root, dry=False)
            print("🚀 Pushed.")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        sys.exit(f"ERROR: command failed with exit code {e.returncode}")
