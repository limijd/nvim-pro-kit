local util = require("config.util")
local tools = require("config.tools")

return {
  name = "nvim-lspconfig",
  dir = util.vendor("nvim-lspconfig"),
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "cmp-nvim-lsp",
  },
  config = function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    local has_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if has_cmp then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    local function on_attach(_, bufnr)
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map("n", "gd", vim.lsp.buf.definition, "Go to definition")
      map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
      map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
      map("n", "gr", vim.lsp.buf.references, "List references")
      map("n", "K", vim.lsp.buf.hover, "Hover documentation")
      map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
      map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
      map("n", "<leader>fd", vim.diagnostic.open_float, "Show diagnostics")
      map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
      map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
    end

    local servers = {
      lua_ls = {
        cmd = tools.lsp_cmd("lua_ls"),
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
            },
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
          },
        },
      },
      pyright = {
        cmd = tools.lsp_cmd("pyright"),
      },
      ts_ls = {
        cmd = tools.lsp_cmd("ts_ls"),
      },
    }

    for server, config in pairs(servers) do
      config = vim.tbl_deep_extend("force", {
        on_attach = on_attach,
        capabilities = capabilities,
      }, config)

      vim.lsp.config(server, config)

      local ok, err = pcall(vim.lsp.enable, server)
      if not ok then
        vim.schedule(function()
          vim.notify(string.format("Failed to enable LSP server '%s': %s", server, err), vim.log.levels.WARN)
        end)
      end
    end
  end,
}
