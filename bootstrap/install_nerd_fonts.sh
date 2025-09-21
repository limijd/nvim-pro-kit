#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap/install_nerd_fonts.sh [--target DIR]

Install the bundled Nerd Fonts into the current user font directory.

When no target is provided, fonts install to:
  • macOS:  ~/Library/Fonts
  • Linux:  ${XDG_DATA_HOME:-$HOME/.local/share}/fonts

Options:
  --target DIR  Install fonts into DIR instead of the platform default
  -h, --help    Show this help message and exit
USAGE
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
FONTS_ROOT="$REPO_ROOT/tools/fonts/NerdFonts"

if [[ ! -d "$FONTS_ROOT" ]]; then
  echo "Unable to locate bundled Nerd Fonts directory at $FONTS_ROOT" >&2
  exit 1
fi

TARGET_DIR=""

determine_default_target() {
  case "$(uname -s)" in
    Darwin)
      printf '%s' "$HOME/Library/Fonts"
      ;;
    Linux)
      printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
      ;;
    *)
      return 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      if [[ $# -lt 2 ]]; then
        echo "--target requires a directory argument" >&2
        exit 1
      fi
      TARGET_DIR="$2"
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

if [[ -z "$TARGET_DIR" ]]; then
  if ! TARGET_DIR="$(determine_default_target)"; then
    echo "Unsupported platform: $(uname -s). Please specify --target." >&2
    exit 1
  fi
fi

mkdir -p "$TARGET_DIR"

if ! command -v unzip >/dev/null 2>&1; then
  echo "The 'unzip' command is required to install fonts." >&2
  exit 1
fi

shopt -s nullglob
archives=("$FONTS_ROOT"/*.zip)
shopt -u nullglob

if [[ ${#archives[@]} -eq 0 ]]; then
  echo "No font archives found in $FONTS_ROOT" >&2
  exit 1
fi

echo "Installing Nerd Fonts into $TARGET_DIR"
for archive in "${archives[@]}"; do
  echo "  -> $(basename "$archive")"
  unzip -o -q "$archive" -d "$TARGET_DIR"
done

echo "Fonts installed."

if command -v fc-cache >/dev/null 2>&1; then
  echo "Refreshing font cache"
  fc-cache -f "$TARGET_DIR" >/dev/null 2>&1 || true
fi

USAGE_GUIDE="Fonts installed to $TARGET_DIR"
echo "$USAGE_GUIDE"
