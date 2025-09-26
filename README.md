# nvim-pro-kit
nvim-pro-kit is a batteries-included Neovim configuration tailored for professional development workflows. Every dependency ships in the repository so you can install it completely offline while keeping your editor setup reproducible and version-controlled.

`nvim-pro-kit` 是为专业开发流程量身打造的全能型 Neovim 配置。所有依赖均已预先内建，即使在离线环境也能快速部署，同时确保编辑器配置可重现且易于版本控制。

## 📚 Table of Contents

- [✨ Highlights](#-highlights)
- [🚀 Installation](#-installation)
- [🧰 Tools](#-tools)
- [🐞 Debugging](#-debugging)
- [📦 Managing Vendored Plugins](#-managing-vendored-plugins)
  - [Plugin manifest](#plugin-manifest)
  - [Running `vendor_update.py`](#running-vendor_updatepy)
  - [Safety checks](#safety-checks)
- [🌳 Tree-sitter Grammars](#-tree-sitter-grammars)
  - [Manifest](#manifest)
  - [Building parsers with `treesitter-sync.py`](#building-parsers-with-treesitter-syncpy)
  - [Vendoring parser sources](#vendoring-parser-sources)
  - [Verification and pruning](#verification-and-pruning)
- [👩‍💻 Contributor Workflow](#-contributor-workflow)
  - [Adding a new plugin](#adding-a-new-plugin)
  - [Updating an existing plugin](#updating-an-existing-plugin)
  - [Removing a plugin](#removing-a-plugin)
  - [Tips](#tips)
- [🛠️ Offline readiness](#️-offline-readiness)
- [🎬 Demo: Fresh CentOS 7 Deployment](#-demo-fresh-centos-7-deployment)
- [🗒️ Release Notes](#-release-notes)

## ✨ Highlights

- **100% vendored**: plugin snapshots, Tree-sitter sources, and runtime headers live inside the repository.
- **Deterministic tooling**: helper scripts read a single manifest file and keep your working tree in sync.
- **Offline friendly**: bootstrap a complete IDE on air-gapped machines by copying this repository and running the provided scripts.

## 🚀 Installation

Use the Python bootstrap installer to set up the configuration without touching the network:

```
python3 bootstrap/install.py
```

By default the installer creates a symbolic link from `<repo>/nvim` to your Neovim config directory (typically `~/.config/nvim`), so the repository layout remains untouched. Pass `--copy` to copy the files instead, `--force` to overwrite an existing config, or `--target DIR` to install somewhere else.

After linking you can start Neovim immediately, even on an offline machine.

## 🧰 Tools

The `tools/` directory ships portable binaries and fonts required by the configuration so that a fresh machine can bootstrap Neovim without reaching the internet. Each tool is stored under a versioned folder (for example `tools/fzf/0.65.2/`) containing upstream release archives alongside their SHA256 sums. Current snapshots include:

- Neovim AppImages for multiple architectures under `tools/nvim/`;
- command-line helpers such as `fzf`, `fd`, `ripgrep`, and `delta`;
- patched Nerd Fonts suitable for terminal glyph rendering.

To use the bundled binaries:

1. Pick the archive that matches your platform (for example `nvim-linux-x86_64.0.11.4.appimage`).
2. Extract or mark it executable as required by the upstream release.
3. Point the relevant `NVIM_PRO_KIT_<TOOL>` environment variable at the unpacked binary when you want the runtime to prefer the vendored artifact.

Inside Neovim you can run the `:Tools` command to inspect the resolved paths for each helper and confirm that your environment variables are applied as expected.

The checksums shipped next to each archive allow you to verify integrity before installing. When updating a tool, drop the new archive and checksum into the appropriate versioned folder, keeping older releases available if multiple environments rely on them.

## 🐞 Debugging

`nvim-pro-kit` ships with a full Debug Adapter Protocol (DAP) experience powered by
[`mfussenegger/nvim-dap`](https://github.com/mfussenegger/nvim-dap),
[`rcarriga/nvim-dap-ui`](https://github.com/rcarriga/nvim-dap-ui), and the bundled
Python helpers. The configuration loads on demand so opening Neovim stays fast,
yet once a debug session starts you get pre-wired UI affordances, tailored
keymaps, and quality-of-life tweaks.

### Default keymaps

Core debugger control lives on the function keys so you can drive a session with
one hand:

| Mapping     | Action                  |
| ----------- | ----------------------- |
| `<F5>`      | Continue / start debug  |
| `<F6>`      | Restart the current run |
| `<F7>`      | Terminate the session   |
| `<F10>`     | Step over               |
| `<F11>`     | Step into               |
| `<F12>`     | Step out                |
| `<F4>`      | Toggle breakpoint       |

Leader mappings cover the rest of the workflow:

| Mapping          | Action                                   |
| ---------------- | ---------------------------------------- |
| `<leader>db`     | Toggle breakpoint                        |
| `<leader>dB`     | Set a conditional breakpoint             |
| `<leader>dl`     | Re-run the last configuration            |
| `<leader>dr`     | Toggle the REPL                          |
| `<leader>du`     | Toggle the DAP UI layout                 |
| `<leader>de`     | Evaluate expression under cursor         |
| `<leader>de` (v) | Evaluate the current visual selection    |
| `<leader>dn`     | Python: debug nearest test (method)      |
| `<leader>dN`     | Python: debug current test class         |
| `<leader>ds` (v) | Python: debug the selected code snippet  |

### Debug UI ergonomics

- DAP UI panels open automatically on session start and close when the adapter
  exits, so the layout never lingers after a run.
- Each panel receives a descriptive winbar title (`DAP: Scopes`, `DAP: Console`,
  …) to help you distinguish split windows at a glance.
- The floating control panel always shows a `DAP: REPL` shortcut next to the
  standard buttons.
- Breakpoints and the current execution point use Nerd Font glyphs that match
  the diagnostic highlight groups, making it easy to see conditions or rejected
  breakpoints in the sign column.

Inside the integrated REPL you can also use the custom `.up` and `.down`
commands to move up or down the stack frame list without reaching for the mouse
or command palette.

## 🔧 External Tool Configuration

The configuration shells out to a handful of external binaries (Git, debuggers, search utilities, language servers, build tools, …).
The `config.tools` module (see `nvim/lua/config/tools/`) exposes one helper per binary (`tools.git()`, `tools.lazygit()`, `tools.ripgrep()`, `tools.lua_ls()`, and so on)
so every plugin reads from the same source of truth.

Each helper follows the same resolution order:

1. honour `$NVIM_PRO_KIT_<TOOL>` when it is set (the variable must point at the executable);
2. probe platform-specific defaults for the current machine (Linux x86_64, Linux aarch64, macOS x86_64, and macOS arm64);
3. fall back to whatever the system exposes on `$PATH`.

Whenever the helper returns an absolute path its parent directory is prepended to `$PATH` automatically so vendored plugins can spawn
the tool without additional configuration.

The module currently resolves the following tools:

- `git`, `lazygit`, and `hg`;
- `ripgrep` (`rg`);
- `python` (debugpy);
- `node`, `npm`, and the Tree-sitter CLI;
- `make` (used to build native Telescope/LuaSnip components);
- `gdb`;
- language servers: `lua_ls`, `pyright`, `ts_ls`;
- compiler candidates for Tree-sitter builds via `tools.compilers()`.

Set `NVIM_PRO_KIT_<TOOL>` (for example `NVIM_PRO_KIT_GIT`, `NVIM_PRO_KIT_LAZYGIT`, `NVIM_PRO_KIT_RIPGREP`, …) to point at custom
executables without editing the repository.

Set `NVIM_PRO_KIT_COMPILERS` to a path-separated list if you need to override the compiler search order; otherwise the helper prefers
`cc`/`gcc`/`clang` on Linux and `clang`/`cc` on macOS. Adjust the platform-specific paths inside `nvim/lua/config/tools/definitions.lua` if you install binaries in
non-standard locations.

## 📦 Managing Vendored Plugins

This repository vendors every Neovim plugin under `vendor/plugins/` using `git subtree`. There are no submodules, runtime downloads, or hidden network calls.

### Plugin manifest

`scripts/plugins-list.yaml` is the single source of truth. The file is JSON-compatible YAML so that it can be parsed with the Python standard library.

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

Keep the list sorted first by `category` and then by `name`. `name` becomes the directory under `vendor/plugins/`, and `ref` may be a branch (main/master/stable), a tag (v1.2.3), or a commit SHA.

### Running `vendor_update.py`

Use `scripts/vendor_update.py` to keep plugins in sync:

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

Additional useful flags:

- `--only NAME1 NAME2`: restricts actions to the provided plugins.
- `--add-only` / `--pull-only`: limit the run to additions or updates.
- `--list`: print the parsed manifest without touching disk.
- `--list-file PATH`: point to an alternate manifest (for experiments).
- `--allow-dirty`: bypass the clean working tree guard (use with care).

### Safety checks

- The script refuses to run on a dirty working tree unless `--allow-dirty` is set.
- `git subtree --squash` is used by default to avoid flooding history with upstream commits.
- Nothing in `vendor/plugins/` is removed unless `--prune` is provided.
- Nested `.git/` directories are rejected to protect against accidental submodules.
- Each run prints a summary and can automatically `git commit` (and optionally `git push`) when `--commit` is supplied.

## 🌳 Tree-sitter Grammars

Tree-sitter grammars are managed with the same level of reproducibility as plugins. A manifest drives both the vendored sources and the compiled parser artifacts so that every machine stays in sync.

### Manifest

`scripts/treesitter-parsers.txt` is the single source of truth for which grammars should be present. Keep it alphabetized. Lines starting with `#` are treated as comments and ignored by tooling. The Neovim config loads this list at startup to ensure all required parsers are present.

### Building parsers with `treesitter-sync.py`

Use `scripts/treesitter-sync.py` to build, verify, and prune parsers from the vendored sources:

```
# Compile every parser listed in the manifest
scripts/treesitter-sync.py

# Skip pruning of unknown grammars (pruning is enabled by default)
scripts/treesitter-sync.py --no-prune

# Only check for drift without touching disk
scripts/treesitter-sync.py --check

# Use a different manifest file
scripts/treesitter-sync.py --manifest path/to/file.txt
```

The script compiles each parser with your platform C compiler (respects `$CC`) and writes both the shared library and a `.revision` marker next to it. By default it ensures the parser installation directory contains exactly the languages listed in the manifest and removes any extras. Use `--check` to validate without compiling.

### Vendoring parser sources

Run `scripts/treesitter-vendor.py` whenever the manifest changes or you need to refresh the vendored Tree-sitter sources. The script asks Neovim (headlessly) for each parser’s `install_info`, clones the upstream repositories, packs the declared source files into `vendor/tree-sitter/<lang>.tar.bz2`, records metadata in `vendor/tree-sitter/metadata.json`, and stages the updated archives so they are ready to commit. It also vendors the Tree-sitter runtime headers required by the compiler.

`scripts/treesitter-vendor.py` always pins repositories to the revisions listed in `vendor/plugins/nvim-treesitter/lockfile.json` so that the vendored sources line up with the parser versions bundled with `nvim-treesitter`. Update that lockfile (by refreshing the vendored `nvim-treesitter` plugin) before re-running the script to ensure reproducible snapshots.

The TypeScript grammar, for example, provides a makefile that bakes in extra linker flags. The vendor script honours that entry point automatically, and you can invoke it manually when debugging a build:

```
tmpdir=$(mktemp -d)
tar -xjf vendor/tree-sitter/typescript.tar.bz2 -C "$tmpdir"
cd "$tmpdir"/typescript/typescript
TS=true make libtree-sitter-typescript.so
```

Setting `TS=true` skips regeneration of `parser.c` while still honoring the flags specified by the grammar authors.

```
# Snapshot parser sources into vendor/tree-sitter/
scripts/treesitter-vendor.py

# Only verify that the committed sources match the manifest
scripts/treesitter-vendor.py --check
```

Set `NVIM_BIN` (or pass `--nvim`) if you want to use a specific Neovim binary (for example the AppImage bundled under `tools/nvim/`). The generated metadata is consumed automatically by both the sync script and the runtime configuration so that `nvim-treesitter` rebuilds every parser from the checked-in sources even on an offline machine. A typical refresh looks like:

1. `scripts/treesitter-vendor.py`
   * Clones or updates each grammar.
   * Compresses the declared sources into `vendor/tree-sitter/*.tar.bz2` archives.
   * Regenerates `metadata.json`.
   * Runs `git add -A vendor/tree-sitter` so the new snapshot is staged.
2. `scripts/treesitter-sync.py`
   * Rebuilds the parsers from the staged sources using your compiler.
   * Optionally prunes stale builds.

Review the staged changes and commit when you are satisfied.

### Verification and pruning

Running `scripts/treesitter-sync.py --check` exits with a non-zero status if any parsers are missing or if unexpected grammars are installed. `scripts/treesitter-vendor.py --check` validates the committed source snapshots without touching disk. Both commands are well-suited for CI or pre-commit hooks.

## 👩‍💻 Contributor Workflow

All contributors should use `scripts/vendor_update.py` to manage plugins consistently. Never edit `vendor/plugins/` by hand.

### Adding a new plugin

1. Edit `scripts/plugins-list.yaml` and add a new JSON/YAML object, keeping the list sorted by `category` then `name`:

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

   This will add the plugin under `vendor/plugins/<NAME>` and commit the change (using the auto-generated message).
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

   This will `git rm -r vendor/plugins/<NAME>` and commit the removal.
3. Open a PR with the changes.

### Tips

* Always use `--dry-run` first if you’re unsure:
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

* All plugins, including `lazy.nvim`, ship in `vendor/plugins/` so no downloads are required at runtime.
* Tree-sitter parsers are compiled from the vendored sources via `scripts/treesitter-sync.py`; no network access is needed after the snapshot is refreshed.
* LSP servers are configured opportunistically: if a language server binary is missing, the configuration skips it and warns once instead of failing.

## 🎬 Demo: Fresh CentOS 7 Deployment

The following walkthrough shows how to bring up `nvim-pro-kit` on a clean CentOS 7 workstation without relying on the public internet. Adapt the paths if your environment differs.

1. **Prepare prerequisites**
   * Install core packages:
     ```bash
     sudo yum install -y git python3
     ```
   * Ensure you have a Neovim binary. You can either use the system package (`sudo yum install -y neovim`) or the portable AppImage provided in this repository under `tools/nvim/`.

2. **Obtain the repository snapshot**
   * Copy the repository bundle (for example via USB drive) to the target machine. If you have network access, a direct clone works too:
    ```bash
    git clone https://github.com/your-org/nvim-pro-kit.git
    ```
  * Change into the project directory:
    ```bash
    cd nvim-pro-kit
    ```

3. **Sync vendored assets**
   * Ensure the vendored plugin snapshot matches `scripts/plugins-list.yaml`:
     ```bash
     scripts/vendor_update.py --dry-run
     ```
     This step is idempotent. On a freshly cloned repository it validates that `vendor/plugins/` already contains the expected commits, and when run with network access it will pull in any missing updates.
   * Build the Tree-sitter parsers from the vendored sources so the `.so`/`.dll` libraries exist locally:
     ```bash
     scripts/treesitter-sync.py
     ```

4. **Install the configuration**
   * Run the Python installer to link the configuration into `$XDG_CONFIG_HOME/nvim` (defaults to `~/.config/nvim`):
     ```bash
     python3 bootstrap/install.py
     ```
   * Use `--copy` if you prefer a physical copy instead of a symlink, or `--target DIR` to install into a custom location.

5. **Launch Neovim**
   * Start Neovim with your preferred binary:
     ```bash
     nvim
     ```
   * The editor loads immediately with all vendored plugins and Tree-sitter grammars, even when completely offline.

6. **Post-install checks (optional)**
   * Verify plugin status with `:Lazy` inside Neovim.

You now have a fully configured Neovim setup ready for professional use on a fresh CentOS 7 machine.

## 🗒️ Release Notes

### v1.0.3 – 2025-09-26

- Fix issues exposed when deploy to old Linux.

### v1.0.2 – 2025-09-26

- Added an Obsidian knowledge base workflow with environment-aware workspace detection, Telescope integration, and leader key mappings for creating, switching, and searching notes.【F:nvim/lua/plugins/obsidian.lua†L1-L86】
- Bundled the `mini.nvim` suite (AI text objects, commenting, surround editing, auto pairs, and MiniClue prompts) so common editing conveniences work out of the box on every install.【F:nvim/lua/plugins/mini.lua†L1-L47】
- Shipped Fugitive commands and keymaps that respect the resolved Git binary, giving a first-class CLI-backed Git experience directly inside Neovim.【F:nvim/lua/plugins/vim-fugitive.lua†L1-L22】
- Hardened the bootstrap installer and Tree-sitter sync script to run on stock Python 3 interpreters by removing the `__future__` dependency and clarifying error handling, improving compatibility on older distributions.【F:bootstrap/install.py†L1-L118】【F:scripts/treesitter-sync.py†L1-L56】
- Updated repository root discovery to follow the utility module’s location when `$NVIM_PRO_KIT_ROOT` is unset, ensuring vendored assets resolve correctly even when the config is copied elsewhere.【F:nvim/lua/config/util.lua†L1-L48】

### v1.0.1 – 2025-09-26

- Extended the DAP REPL with `.up` and `.down` commands so you can walk the call stack without leaving the keyboard, complementing the curated debug keymaps and sign icons.【F:nvim/lua/plugins/nvim-dap.lua†L8-L43】
- Display buffer identifiers in Bufferline to match the picker UI and streamline buffer jumps during large sessions.【F:nvim/lua/plugins/bufferline.lua†L32-L70】
- Tweaked ToggleTerm floating terminal defaults (curved border, zero winblend) to keep the cursor visible and readable across terminal emulators.【F:nvim/lua/plugins/toggleterm.lua†L12-L22】
- Tuned clangd launch arguments to cap indexing threads and memory usage, making remote or resource-constrained development smoother.【F:nvim/lua/config/tools/init.lua†L101-L118】
- Stopped forcing the global `unnamedplus` clipboard, eliminating stray OSC52 artifacts when running inside tmux panes.【F:nvim/lua/config/options.lua†L3-L20】

### v1.0.0 – 2025-09-23

- Initial general availability release with every Neovim plugin, Tree-sitter grammar, and helper CLI vendored for offline installation.【F:CHANGELOG.md†L6-L13】
- Python bootstrap installer that links the repository into a user’s configuration directory while offering automatic backups.【F:CHANGELOG.md†L15-L16】【F:bootstrap/install.py†L1-L118】
- Manifest-driven maintenance scripts (`vendor_update.py`, `treesitter-sync.py`, and `treesitter-vendor.py`) that keep plugins and parsers reproducible.【F:CHANGELOG.md†L7-L13】【F:scripts/treesitter-sync.py†L1-L56】

See [`CHANGELOG.md`](./CHANGELOG.md) for the complete history and upgrade guidance.
