return function(api)
  local define = api.define
  local resolve = api.resolve
  local mason_tool = api.mason_tool

  define(
    "git",
    function()
      return resolve("NVIM_PRO_KIT_GIT", {
        linux_x86_64 = { "/usr/bin/git", "/usr/local/bin/git" },
        linux_aarch64 = { "/usr/bin/git", "/usr/local/bin/git" },
        macos_x86_64 = { "/usr/local/bin/git" },
        macos_arm64 = { "/opt/homebrew/bin/git" },
      }, { "git" })
    end,
    {
      description = "Git distributed version control system.",
      plugins = { "git-worktree.nvim", "gitsigns.nvim", "diffview.nvim", "vim-fugitive" },
    }
  )

  define(
    "lazygit",
    function()
      return resolve("NVIM_PRO_KIT_LAZYGIT", {
        linux_x86_64 = { "/usr/bin/lazygit", "/usr/local/bin/lazygit" },
        linux_aarch64 = { "/usr/bin/lazygit", "/usr/local/bin/lazygit" },
        macos_x86_64 = { "/usr/local/bin/lazygit" },
        macos_arm64 = { "/opt/homebrew/bin/lazygit" },
      }, { "lazygit" })
    end,
    {
      description = "Lazygit terminal user interface for Git repositories.",
      plugins = { "lazygit.nvim" },
    }
  )

  define(
    "ripgrep",
    function()
      return resolve("NVIM_PRO_KIT_RIPGREP", {
        linux_x86_64 = { "/usr/bin/rg", "/usr/local/bin/rg" },
        linux_aarch64 = { "/usr/bin/rg", "/usr/local/bin/rg" },
        macos_x86_64 = { "/usr/local/bin/rg" },
        macos_arm64 = { "/opt/homebrew/bin/rg" },
      }, { "rg" })
    end,
    {
      description = "ripgrep fast text searching utility used for project navigation.",
      plugins = { "telescope.nvim" },
    }
  )

  define(
    "python",
    function()
      return resolve("NVIM_PRO_KIT_PYTHON", {
        linux_x86_64 = { "/usr/bin/python3", "/usr/bin/python" },
        linux_aarch64 = { "/usr/bin/python3", "/usr/bin/python" },
        macos_x86_64 = { "/usr/local/bin/python3", "/usr/bin/python3" },
        macos_arm64 = { "/opt/homebrew/bin/python3", "/usr/bin/python3" },
      }, { "python3", "python" })
    end,
    {
      description = "Python interpreter for debugging and tooling integration.",
      plugins = { "nvim-dap-python" },
    }
  )

  define(
    "node",
    function()
      return resolve("NVIM_PRO_KIT_NODE", {
        linux_x86_64 = { "/usr/bin/node", "/usr/local/bin/node" },
        linux_aarch64 = { "/usr/bin/node", "/usr/local/bin/node" },
        macos_x86_64 = { "/usr/local/bin/node" },
        macos_arm64 = { "/opt/homebrew/bin/node" },
      }, { "node" })
    end,
    {
      description = "Node.js runtime for JavaScript and TypeScript tooling.",
      plugins = {},
    }
  )

  define(
    "npm",
    function()
      return resolve("NVIM_PRO_KIT_NPM", {
        linux_x86_64 = { "/usr/bin/npm", "/usr/local/bin/npm" },
        linux_aarch64 = { "/usr/bin/npm", "/usr/local/bin/npm" },
        macos_x86_64 = { "/usr/local/bin/npm" },
        macos_arm64 = { "/opt/homebrew/bin/npm" },
      }, { "npm" })
    end,
    {
      description = "npm package manager for Node.js-based tooling.",
      plugins = {},
    }
  )

  define(
    "tree_sitter",
    function()
      return resolve("NVIM_PRO_KIT_TREE_SITTER", {
        linux_x86_64 = { "/usr/bin/tree-sitter", "/usr/local/bin/tree-sitter" },
        linux_aarch64 = { "/usr/bin/tree-sitter", "/usr/local/bin/tree-sitter" },
        macos_x86_64 = { "/usr/local/bin/tree-sitter" },
        macos_arm64 = { "/opt/homebrew/bin/tree-sitter" },
      }, { "tree-sitter" })
    end,
    {
      description = "Tree-sitter CLI for working with parser grammars.",
      plugins = {},
    }
  )

  define(
    "make",
    function()
      return resolve("NVIM_PRO_KIT_MAKE", {
        linux_x86_64 = { "/usr/bin/make", "/usr/local/bin/make" },
        linux_aarch64 = { "/usr/bin/make", "/usr/local/bin/make" },
        macos_x86_64 = { "/usr/local/bin/gmake", "/usr/bin/make" },
        macos_arm64 = { "/opt/homebrew/bin/gmake", "/usr/bin/make" },
      }, { "gmake", "make" })
    end,
    {
      description = "Make build tool required for compiling native dependencies.",
      plugins = { "telescope-fzf-native.nvim", "LuaSnip" },
    }
  )

  define(
    "gdb",
    function()
      return resolve("NVIM_PRO_KIT_GDB", {
        linux_x86_64 = { "/usr/bin/gdb", "/usr/local/bin/gdb" },
        linux_aarch64 = { "/usr/bin/gdb", "/usr/local/bin/gdb" },
        macos_x86_64 = { "/usr/local/bin/gdb" },
        macos_arm64 = { "/opt/homebrew/bin/gdb" },
      }, { "gdb" })
    end,
    {
      description = "GNU Debugger integration for native debugging workflows.",
      plugins = { "nvim-gdb" },
    }
  )

  define(
    "lua_ls",
    function()
      local mason = mason_tool("lua-language-server")
      return resolve("NVIM_PRO_KIT_LUA_LS", {
        linux_x86_64 = { "/usr/bin/lua-language-server", mason },
        linux_aarch64 = { "/usr/bin/lua-language-server", mason },
        macos_x86_64 = { "/usr/local/bin/lua-language-server", mason },
        macos_arm64 = { "/opt/homebrew/bin/lua-language-server", mason },
      }, { mason, "lua-language-server" })
    end,
    {
      description = "Lua Language Server for Lua development.",
      plugins = { "nvim-lspconfig" },
    }
  )

  define(
    "pyright",
    function()
      local mason = mason_tool("pyright-langserver")
      return resolve("NVIM_PRO_KIT_PYRIGHT", {
        linux_x86_64 = { "/usr/bin/pyright-langserver", "/usr/local/bin/pyright-langserver", mason },
        linux_aarch64 = { "/usr/bin/pyright-langserver", "/usr/local/bin/pyright-langserver", mason },
        macos_x86_64 = { "/usr/local/bin/pyright-langserver", mason },
        macos_arm64 = { "/opt/homebrew/bin/pyright-langserver", mason },
      }, { mason, "pyright-langserver" })
    end,
    {
      description = "Pyright Language Server for Python projects.",
      plugins = { "nvim-lspconfig" },
    }
  )

  define(
    "ts_ls",
    function()
      local mason = mason_tool("typescript-language-server")
      return resolve("NVIM_PRO_KIT_TS_LS", {
        linux_x86_64 = { "/usr/bin/typescript-language-server", "/usr/local/bin/typescript-language-server", mason },
        linux_aarch64 = { "/usr/bin/typescript-language-server", "/usr/local/bin/typescript-language-server", mason },
        macos_x86_64 = { "/usr/local/bin/typescript-language-server", mason },
        macos_arm64 = { "/opt/homebrew/bin/typescript-language-server", mason },
      }, { mason, "typescript-language-server" })
    end,
    {
      description = "TypeScript Language Server for JavaScript and TypeScript.",
      plugins = { "nvim-lspconfig" },
    }
  )

  define(
    "clangd",
    function()
      local mason = mason_tool("clangd")
      return resolve("NVIM_PRO_KIT_CLANGD", {
        linux_x86_64 = { "/usr/bin/clangd", "/usr/local/bin/clangd", mason },
        linux_aarch64 = { "/usr/bin/clangd", "/usr/local/bin/clangd", mason },
        macos_x86_64 = { "/usr/local/opt/llvm/bin/clangd", "/usr/local/bin/clangd", mason },
        macos_arm64 = { "/opt/homebrew/opt/llvm/bin/clangd", "/opt/homebrew/bin/clangd", mason },
      }, { mason, "clangd" })
    end,
    {
      description = "Clangd language server providing C and C++ support.",
      plugins = { "nvim-lspconfig" },
    }
  )

  define(
    "hg",
    function()
      return resolve("NVIM_PRO_KIT_HG", {
        linux_x86_64 = { "/usr/bin/hg", "/usr/local/bin/hg" },
        linux_aarch64 = { "/usr/bin/hg", "/usr/local/bin/hg" },
        macos_x86_64 = { "/usr/local/bin/hg" },
        macos_arm64 = { "/opt/homebrew/bin/hg" },
      }, { "hg" })
    end,
    {
      description = "Mercurial distributed version control client.",
      plugins = { "diffview.nvim" },
    }
  )
end
