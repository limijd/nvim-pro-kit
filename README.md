# nvim-pro-kit
nvim professionl all-in-one kit which is offline installation friendly

## 📦 Managing Vendored Plugins

This repo vendors all Neovim plugins under vendor/plugins/

using git-subtree.
You never need git submodule, networked plugin managers, or runtime downloads.
Everything is reproducible and offline-ready.

### Plugin list

The single source of truth is scripts/plugins-list.txt

```
# URL                                         NAME                   REF
https://github.com/folke/lazy.nvim            lazy.nvim              stable
https://github.com/nvim-lua/plenary.nvim      plenary.nvim           master
https://github.com/nvim-telescope/telescope.nvim telescope.nvim      master
# …etc

    URL → plugin upstream repository

    NAME → folder name under vendor/plugins/

    REF → branch, tag, or commit (e.g. main, stable, v0.1.6, abcd1234)
```

### Syncing plugins

Use scripts/vendor_update.py to keep plugins in sync.

```
# Preview actions (no changes)
scripts/vendor_update.py --dry-run

# Add missing plugins & update existing ones, then commit
scripts/vendor_update.py --commit

# Add/update only specific plugins
scripts/vendor_update.py --only telescope.nvim nvim-cmp --commit

# Also remove any directories not listed in plugins-list.txt
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

All contributors should use vendor_update.py to manage plugins consistently. Never edit vendor/plugins/ by hand. 

### Adding a new plugin

1. Edit scripts/plugins-list.txt and add a new line:
```
https://github.com/owner/repo-name   repo-name   main
```
    * URL: upstream GitHub repo
    * NAME: short folder name under vendor/plugins/
    * REF: branch, tag, or commit SHA
2. Run the sync script: 
```
scripts/vendor_update.py --commit
```
This will add the plugin under vendor/plugins/<NAME> and commit the change.
3. Open a pull request with both the list change and the new commit.

### Updating an existing plugin

1. Decide the new version:
    * For latest branch (main, master, stable) → nothing to change in the list.
    * For a specific release → update the REF in plugins-list.txt to the new tag or commit.

2. Run:
```
scripts/vendor_update.py --only <plugin-name> --commit
```

3. Verify locally, then push and open a PR.

### Removing a plugin

1. Delete its line from plugins-list.txt.
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

