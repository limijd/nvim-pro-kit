local util = require("config.util")
local tools = require("config.tools")

local function has_tool(name)
  return function()
    return tools.has(name)
  end
end

return {
  name = "conform.nvim",
  dir = util.vendor("conform.nvim"),
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({
          async = true,
          lsp_fallback = true,
        })
      end,
      desc = "Format buffer",
      mode = "n",
      silent = true,
    },
  },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { { "prettierd", "prettier" } },
        javascriptreact = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
        typescriptreact = { { "prettierd", "prettier" } },
        json = { { "prettierd", "prettier" } },
        html = { { "prettierd", "prettier" } },
        css = { { "prettierd", "prettier" } },
        scss = { { "prettierd", "prettier" } },
        markdown = { { "prettierd", "prettier" } },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        c = { "clang_format" },
        cpp = { "clang_format" },
      },
      formatters = {
        stylua = { condition = has_tool("stylua") },
        black = { condition = has_tool("black") },
        prettierd = { condition = has_tool("prettierd") },
        prettier = { condition = has_tool("prettier") },
        clang_format = { condition = has_tool("clang_format") },
        shfmt = { condition = has_tool("shfmt") },
      },
      format_on_save = function(bufnr)
        if vim.g.conform_disable_autoformat or vim.b[bufnr].conform_disable_autoformat then
          return
        end
        if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "" then
          return
        end
        return { lsp_fallback = true }
      end,
    })

    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        vim.b.conform_disable_autoformat = true
      else
        vim.g.conform_disable_autoformat = true
      end
    end, { desc = "Disable autoformat on save", bang = true })

    vim.api.nvim_create_user_command("FormatEnable", function(args)
      if args.bang then
        vim.b.conform_disable_autoformat = nil
      else
        vim.g.conform_disable_autoformat = nil
      end
    end, { desc = "Enable autoformat on save", bang = true })
  end,
}
