#!/usr/bin/env python3
"""
One-stop subtree sync:
  - If vendor/plugins/<name> is missing -> subtree add
  - Else -> subtree pull
Reads: scripts/plugins-list.txt (format: URL NAME REF; '#' comments allowed)

Usage:
  scripts/vendor_update.py
  scripts/vendor_update.py --only telescope.nvim nvim-cmp
  scripts/vendor_update.py --add-only
  scripts/vendor_update.py --pull-only
  scripts/vendor_update.py --no-squash
  scripts/vendor_update.py --allow-dirty
  scripts/vendor_update.py --dry-run
  scripts/vendor_update.py --commit
"""
from __future__ import annotations
import argparse, subprocess, sys, shlex, datetime
from pathlib import Path
from typing import List, Tuple

VENDOR_DIR = Path("vendor/plugins")
LIST_FILE = Path("scripts/plugins-list.txt")


def run(cmd: List[str], cwd: Path, dry: bool) -> None:
    print(" ", "$", " ".join(shlex.quote(x) for x in cmd))
    if not dry:
        subprocess.run(cmd, cwd=cwd, check=True)


def repo_root() -> Path:
    out = subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True
    ).strip()
    return Path(out)


def clean_tree_required(allow_dirty: bool, root: Path) -> None:
    if allow_dirty:
        return
    rc1 = subprocess.run(["git", "diff", "--quiet"], cwd=root).returncode
    rc2 = subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=root).returncode
    if rc1 != 0 or rc2 != 0:
        sys.exit("ERROR: Working tree not clean. Commit/stash or use --allow-dirty.")


def parse_list(list_file: Path) -> List[Tuple[str, str, str]]:
    lines = list_file.read_text(encoding="utf-8").splitlines()
    items: List[Tuple[str, str, str]] = []
    for raw in lines:
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        parts = s.split()
        if len(parts) < 3:
            sys.exit(f"ERROR: Bad line in {list_file}: {raw!r}")
        url, name, ref = parts[0], parts[1], parts[2]
        items.append((url, name, ref))
    return items


def add(root: Path, url: str, name: str, ref: str, squash: bool, dry: bool) -> None:
    path = VENDOR_DIR / name
    print(f"➕ subtree add  {name}  ({ref})")
    cmd = ["git", "subtree", "add", "--prefix", str(path), url, ref]
    if squash:
        cmd.append("--squash")
    run(cmd, cwd=root, dry=dry)


def pull(root: Path, url: str, name: str, ref: str, squash: bool, dry: bool) -> None:
    path = VENDOR_DIR / name
    print(f"🔄 subtree pull {name}  ({ref})")
    if not dry:
        subprocess.run(["git", "fetch", url, ref, "--no-tags", "--depth=1"], cwd=root)
    cmd = ["git", "subtree", "pull", "--prefix", str(path), url, ref]
    if squash:
        cmd.append("--squash")
    run(cmd, cwd=root, dry=dry)


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Add-or-update all subtree vendor plugins."
    )
    ap.add_argument(
        "--only", nargs="+", default=[], help="Only update specific plugin names"
    )
    ap.add_argument("--add-only", action="store_true", help="Only add missing plugins")
    ap.add_argument(
        "--pull-only", action="store_true", help="Only pull existing plugins"
    )
    ap.add_argument(
        "--no-squash",
        action="store_true",
        help="Keep full upstream history (default squashes)",
    )
    ap.add_argument(
        "--allow-dirty", action="store_true", help="Skip clean working-tree check"
    )
    ap.add_argument(
        "--dry-run", action="store_true", help="Show actions but don’t run them"
    )
    ap.add_argument(
        "--commit", action="store_true", help="Auto git commit after changes"
    )
    args = ap.parse_args()

    root = repo_root()
    clean_tree_required(args.allow_dirty, root)

    (root / VENDOR_DIR).mkdir(parents=True, exist_ok=True)
    items = parse_list(root / LIST_FILE)
    only = set(args.only)
    squash = not args.no_squash

    added = updated = skipped = 0
    for url, name, ref in items:
        if only and name not in only:
            skipped += 1
            continue
        path = root / VENDOR_DIR / name
        if path.exists():
            if args.add_only:
                print(f"⏭  exists, skip add: {name}")
                skipped += 1
            else:
                pull(root, url, name, ref, squash, args.dry_run)
                updated += 1
        else:
            if args.pull_only:
                print(f"⏭  missing, skip pull: {name}")
                skipped += 1
            else:
                add(root, url, name, ref, squash, args.dry_run)
                added += 1

    print(f"✅ Done. added={added} updated={updated} skipped={skipped}")

    # Auto commit if requested and not dry-run
    if args.commit and not args.dry_run and (added or updated):
        msg = f"chore: vendor plugins sync {datetime.date.today().isoformat()}"
        run(["git", "commit", "-am", msg], cwd=root, dry=False)
        print(f"💾 Auto committed with message: {msg}")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as e:
        sys.exit(f"ERROR: command failed with exit code {e.returncode}")
