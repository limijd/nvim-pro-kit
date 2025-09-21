#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap/install.sh [--copy] [--force] [--target DIR]

Install this Neovim configuration into your system without requiring network
access. By default the script creates a symbolic link at
$XDG_CONFIG_HOME/nvim (or ~/.config/nvim) pointing to the repository.

Options:
  --copy        Copy files instead of creating a symlink
  --force       Overwrite the target directory instead of creating a backup
  --target DIR  Install to DIR instead of the default
  -h, --help    Show this message and exit
USAGE
}

MODE="link"
FORCE=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      MODE="copy"
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --target)
      if [[ $# -lt 2 ]]; then
        echo "--target requires a directory argument" >&2
        exit 1
      fi
      TARGET="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
NVIM_ROOT="$REPO_ROOT/nvim"
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
TARGET=${TARGET:-"$CONFIG_HOME/nvim"}

if [[ ! -d "$REPO_ROOT/vendor/plugins/lazy.nvim" ]]; then
  echo "lazy.nvim vendor directory is missing; installation cannot continue." >&2
  exit 1
fi

if [[ ! -d "$NVIM_ROOT" ]]; then
  echo "Repository is missing the nvim/ directory expected to contain init.lua" >&2
  exit 1
fi

if [[ -e "$TARGET" || -L "$TARGET" ]]; then
  if [[ $FORCE -eq 1 ]]; then
    rm -rf "$TARGET"
  else
    timestamp=$(date +%Y%m%d%H%M%S)
    backup="${TARGET}.backup.${timestamp}"
    echo "Existing Neovim config detected. Moving it to $backup"
    mv "$TARGET" "$backup"
  fi
fi

mkdir -p "$(dirname "$TARGET")"

if [[ $MODE == "link" ]]; then
  ln -s "$NVIM_ROOT" "$TARGET"
else
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude ".git" "$NVIM_ROOT/" "$TARGET/"
  else
    cp -a "$NVIM_ROOT/." "$TARGET/"
  fi
fi

echo "Neovim configuration installed to $TARGET"

echo "You can now start Neovim without an internet connection using: nvim"
