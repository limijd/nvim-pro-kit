# nvim-pro-kit
nvim-pro-kit is a batteries-included Neovim configuration tailored for professional development workflows. Every dependency is vendored so you can install it completely offline while keeping your editor setup reproducible and version-controlled.

## 🚀 Installation

Use the Python bootstrap installer to set up the configuration without touching
the network:

```
python3 bootstrap/install.py
```

It mirrors the previous shell script, creating a symbolic link at
`$XDG_CONFIG_HOME/nvim` (or `~/.config/nvim`) pointing to the repo's `nvim/`
directory. Pass `--copy` if you prefer a physical copy, `--force` to overwrite
an existing config, or `--target DIR` to install somewhere else. You can still
run `bootstrap/install.sh` if you need a pure POSIX shell workflow.

After linking you can start Neovim immediately, even on an offline machine.

## 📦 Managing Vendored Plugins

This repo vendors all Neovim plugins under vendor/plugins/

using git-subtree.
You never need git submodule, networked plugin managers, or runtime downloads.
Everything is reproducible and offline-ready.

### Plugin list

The single source of truth is `scripts/plugins-list.yaml`.

```yaml
[
  {
    "name": "lazy.nvim",
    "url": "https://github.com/folke/lazy.nvim",
    "ref": "stable",
    "category": "core",
    "description": "Plugin manager that lazily loads Neovim plugins for fast startup.",
    "depends": []
  },
  {
    "name": "plenary.nvim",
    "url": "https://github.com/nvim-lua/plenary.nvim",
    "ref": "master",
    "category": "library",
    "description": "Utility Lua functions used by many Neovim plugins.",
    "depends": []
  }
]
```

Although the file is YAML, we keep it JSON-compatible for simplicity. Each entry
is sorted by `category` and `name`. `name` becomes the folder under
`vendor/plugins/`, and `ref` may be a branch (main/master), a tag (v1.2.3), or a
commit SHA.

### Syncing plugins

Use `scripts/vendor_update.py` to keep plugins in sync.

```
# Preview actions (no changes)
scripts/vendor_update.py --dry-run

# Add missing plugins & update existing ones, then commit
scripts/vendor_update.py --commit

# Add/update only specific plugins
scripts/vendor_update.py --only telescope.nvim nvim-cmp --commit

# Also remove any directories not listed in plugins-list.yaml
scripts/vendor_update.py --prune --commit

# Keep full upstream history instead of squashing (not recommended)
scripts/vendor_update.py --no-squash --commit

# Commit and push in one step
scripts/vendor_update.py --commit --push
```

### Safety

* By default the script refuses to run on a dirty working tree. Use --allow-dirty if you know what you’re doing.
* We strongly recommend keeping --squash (the default) to prevent thousands of upstream commits polluting your repo history.
* Removal (--prune) is opt-in: nothing is deleted unless you request it.
* If something goes wrong, simply revert the last commit — the previous snapshot is preserved in Git history.

## 👩‍💻 Contributor Workflow

All contributors should use `vendor_update.py` to manage plugins consistently. Never edit `vendor/plugins/` by hand.

### Adding a new plugin

1. Edit `scripts/plugins-list.yaml` and add a new JSON/YAML object, keeping the
   list sorted by `category` then `name`:
```yaml
{
  "name": "repo-name",
  "url": "https://github.com/owner/repo-name",
  "ref": "main",
  "category": "…",
  "description": "One-line summary of what the plugin does.",
  "depends": []
}
```
    * `url`: upstream GitHub repo.
    * `name`: short folder name under `vendor/plugins/`.
    * `ref`: branch, tag, or commit SHA.
    * `category`: grouping used for display/sorting (completion, lsp, etc.).
    * `description`: brief purpose of the plugin.
    * `depends`: array of plugin names that must be present first.
2. Run the sync script: 
```
scripts/vendor_update.py --commit
```
This will add the plugin under vendor/plugins/<NAME> and commit the change.
3. Open a pull request with both the list change and the new commit.

### Updating an existing plugin

1. Decide the new version:
    * For latest branch (main, master, stable) → nothing to change in the list.
    * For a specific release → update the `ref` in `plugins-list.yaml` to the new tag or commit.

2. Run:
```
scripts/vendor_update.py --only <plugin-name> --commit
```

3. Verify locally, then push and open a PR.

### Removing a plugin

1. Delete its entry from `scripts/plugins-list.yaml`.
2. Run:
```
scripts/vendor_update.py --prune --commit
```
This will git rm -r vendor/plugins/<NAME> and commit the removal.
3. Open a PR with the changes.

### Notes

* Always use --dry-run first if you’re unsure:
```
scripts/vendor_update.py --dry-run
```
* If you want to sync everything at once:
```
scripts/vendor_update.py --commit
```
* If you want to sync and push in one go:
```
scripts/vendor_update.py --commit --push
```

## 🛠️ Offline readiness

* All plugins, including `lazy.nvim`, ship in `vendor/plugins/` so no downloads
  are required at runtime.
* Treesitter parsers are not auto-downloaded; run `:TSInstall <lang>` when you
  have the appropriate toolchains available.
* LSP servers are configured opportunistically: if a language server binary is
  missing, the configuration skips it and warns once instead of failing.

