return function(api)
  local define = api.define
  local resolve = api.resolve
  local mason_tool = api.mason_tool
  local repo_root = api.repo_root

  local function repo_tool(path)
    if not repo_root or repo_root == "" then
      return nil
    end
    return repo_root .. "/" .. path
  end

  define(
    "git",
    function()
      return resolve("NVIM_PRO_KIT_GIT", {
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/git/latest/git"),
          "/usr/bin/git",
          "/usr/local/bin/git",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/git/latest/git"),
          "/usr/bin/git",
          "/usr/local/bin/git",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/git/latest/git"),
          "/usr/local/bin/git",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/git/latest/git"),
          "/opt/homebrew/bin/git",
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/lazygit/latest/lazygit"),
          "/usr/bin/lazygit",
          "/usr/local/bin/lazygit",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/lazygit/latest/lazygit"),
          "/usr/bin/lazygit",
          "/usr/local/bin/lazygit",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/lazygit/latest/lazygit"),
          "/usr/local/bin/lazygit",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/lazygit/latest/lazygit"),
          "/opt/homebrew/bin/lazygit",
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/ripgrep/latest/rg"),
          "/usr/bin/rg",
          "/usr/local/bin/rg",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/ripgrep/latest/rg"),
          "/usr/bin/rg",
          "/usr/local/bin/rg",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/ripgrep/latest/rg"),
          "/usr/local/bin/rg",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/ripgrep/latest/rg"),
          "/opt/homebrew/bin/rg",
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/python/latest/python3"),
          repo_tool("tools/linux_x86_64/python3/latest/python3"),
          "/usr/bin/python3",
          "/usr/bin/python",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/python/latest/python3"),
          repo_tool("tools/linux_aarch64/python3/latest/python3"),
          "/usr/bin/python3",
          "/usr/bin/python",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/python/latest/python3"),
          repo_tool("tools/macos_x86_64/python3/latest/python3"),
          "/usr/local/bin/python3",
          "/usr/bin/python3",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/python/latest/python3"),
          repo_tool("tools/macos_arm64/python3/latest/python3"),
          "/opt/homebrew/bin/python3",
          "/usr/bin/python3",
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/node/latest/node"),
          "/usr/bin/node",
          "/usr/local/bin/node",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/node/latest/node"),
          "/usr/bin/node",
          "/usr/local/bin/node",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/node/latest/node"),
          "/usr/local/bin/node",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/node/latest/node"),
          "/opt/homebrew/bin/node",
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/npm/latest/npm"),
          "/usr/bin/npm",
          "/usr/local/bin/npm",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/npm/latest/npm"),
          "/usr/bin/npm",
          "/usr/local/bin/npm",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/npm/latest/npm"),
          "/usr/local/bin/npm",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/npm/latest/npm"),
          "/opt/homebrew/bin/npm",
        },
      }, { "npm" })
    end,
    {
      description = "npm package manager for Node.js-based tooling.",
      plugins = {},
    }
  )

  define(
    "make",
    function()
      return resolve("NVIM_PRO_KIT_MAKE", {
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/make/latest/make"),
          "/usr/bin/make",
          "/usr/local/bin/make",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/make/latest/make"),
          "/usr/bin/make",
          "/usr/local/bin/make",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/make/latest/gmake"),
          repo_tool("tools/macos_x86_64/make/latest/make"),
          "/usr/local/bin/gmake",
          "/usr/bin/make",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/make/latest/gmake"),
          repo_tool("tools/macos_arm64/make/latest/make"),
          "/opt/homebrew/bin/gmake",
          "/usr/bin/make",
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/gdb/latest/gdb"),
          "/usr/bin/gdb",
          "/usr/local/bin/gdb",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/gdb/latest/gdb"),
          "/usr/bin/gdb",
          "/usr/local/bin/gdb",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/gdb/latest/gdb"),
          "/usr/local/bin/gdb",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/gdb/latest/gdb"),
          "/opt/homebrew/bin/gdb",
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/lua-language-server/latest/bin/lua-language-server"),
          repo_tool("tools/linux_x86_64/lua-language-server/latest/lua-language-server"),
          "/usr/bin/lua-language-server",
          mason,
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/lua-language-server/latest/bin/lua-language-server"),
          repo_tool("tools/linux_aarch64/lua-language-server/latest/lua-language-server"),
          "/usr/bin/lua-language-server",
          mason,
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/lua-language-server/latest/bin/lua-language-server"),
          repo_tool("tools/macos_x86_64/lua-language-server/latest/lua-language-server"),
          "/usr/local/bin/lua-language-server",
          mason,
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/lua-language-server/latest/bin/lua-language-server"),
          repo_tool("tools/macos_arm64/lua-language-server/latest/lua-language-server"),
          "/opt/homebrew/bin/lua-language-server",
          mason,
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/pyright/latest/pyright-langserver"),
          repo_tool("tools/linux_x86_64/pyright-langserver/latest/pyright-langserver"),
          "/usr/bin/pyright-langserver",
          "/usr/local/bin/pyright-langserver",
          mason,
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/pyright/latest/pyright-langserver"),
          repo_tool("tools/linux_aarch64/pyright-langserver/latest/pyright-langserver"),
          "/usr/bin/pyright-langserver",
          "/usr/local/bin/pyright-langserver",
          mason,
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/pyright/latest/pyright-langserver"),
          repo_tool("tools/macos_x86_64/pyright-langserver/latest/pyright-langserver"),
          "/usr/local/bin/pyright-langserver",
          mason,
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/pyright/latest/pyright-langserver"),
          repo_tool("tools/macos_arm64/pyright-langserver/latest/pyright-langserver"),
          "/opt/homebrew/bin/pyright-langserver",
          mason,
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/typescript-language-server/latest/typescript-language-server"),
          repo_tool("tools/linux_x86_64/tsserver/latest/typescript-language-server"),
          "/usr/bin/typescript-language-server",
          "/usr/local/bin/typescript-language-server",
          mason,
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/typescript-language-server/latest/typescript-language-server"),
          repo_tool("tools/linux_aarch64/tsserver/latest/typescript-language-server"),
          "/usr/bin/typescript-language-server",
          "/usr/local/bin/typescript-language-server",
          mason,
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/typescript-language-server/latest/typescript-language-server"),
          repo_tool("tools/macos_x86_64/tsserver/latest/typescript-language-server"),
          "/usr/local/bin/typescript-language-server",
          mason,
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/typescript-language-server/latest/typescript-language-server"),
          repo_tool("tools/macos_arm64/tsserver/latest/typescript-language-server"),
          "/opt/homebrew/bin/typescript-language-server",
          mason,
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/clangd/latest/clangd"),
          "/usr/bin/clangd",
          "/usr/local/bin/clangd",
          mason,
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/clangd/latest/clangd"),
          "/usr/bin/clangd",
          "/usr/local/bin/clangd",
          mason,
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/clangd/latest/clangd"),
          "/usr/local/opt/llvm/bin/clangd",
          "/usr/local/bin/clangd",
          mason,
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/clangd/latest/clangd"),
          "/opt/homebrew/opt/llvm/bin/clangd",
          "/opt/homebrew/bin/clangd",
          mason,
        },
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
        linux_x86_64 = {
          repo_tool("tools/linux_x86_64/hg/latest/hg"),
          repo_tool("tools/linux_x86_64/mercurial/latest/hg"),
          "/usr/bin/hg",
          "/usr/local/bin/hg",
        },
        linux_aarch64 = {
          repo_tool("tools/linux_aarch64/hg/latest/hg"),
          repo_tool("tools/linux_aarch64/mercurial/latest/hg"),
          "/usr/bin/hg",
          "/usr/local/bin/hg",
        },
        macos_x86_64 = {
          repo_tool("tools/macos_x86_64/hg/latest/hg"),
          repo_tool("tools/macos_x86_64/mercurial/latest/hg"),
          "/usr/local/bin/hg",
        },
        macos_arm64 = {
          repo_tool("tools/macos_arm64/hg/latest/hg"),
          repo_tool("tools/macos_arm64/mercurial/latest/hg"),
          "/opt/homebrew/bin/hg",
        },
      }, { "hg" })
    end,
    {
      description = "Mercurial distributed version control client.",
      plugins = { "diffview.nvim" },
    }
  )
end
