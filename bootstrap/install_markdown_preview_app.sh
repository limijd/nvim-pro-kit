#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap/install_markdown_preview_app.sh

Install npm dependencies for markdown-preview.nvim plugin.

This script runs 'npm install' in the plugin's app directory to enable
browser-based Markdown preview functionality.

Options:
  -h, --help    Show this help message and exit
USAGE
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
APP_DIR="$REPO_ROOT/vendor/plugins/markdown-preview.nvim/app"

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ ! -d "$APP_DIR" ]]; then
  echo "markdown-preview.nvim app directory not found at $APP_DIR" >&2
  echo "Please ensure the plugin is vendored first." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required but not found in PATH." >&2
  echo "Please install Node.js and npm first." >&2
  exit 1
fi

echo "Installing markdown-preview.nvim dependencies..."
cd "$APP_DIR"
npm install --silent

echo "Done. You can now use :MarkdownPreview in Neovim."
