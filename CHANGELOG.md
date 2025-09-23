# Changelog

All notable changes to this project are documented in this file.

## v1.0.0 - 2025-09-23

### Added
- Initial general availability release with every Neovim plugin, Tree-sitter grammar, and helper CLI vendored for offline installation.
- Python bootstrap installer that safely links the repository into a user's configuration directory while offering automatic backups.
- Manifest-driven maintenance scripts (`vendor_update.py`, `treesitter-sync.py`, and `treesitter-vendor.py`) that keep plugins and parsers reproducible.

### Usage Notes
- Run `python3 bootstrap/install.py` to link the configuration into place on target machines.
- Re-run the maintenance scripts when updating plugin or parser manifests to regenerate vendored assets before cutting the next release.
