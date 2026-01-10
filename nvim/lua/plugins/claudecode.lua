local util = require("config.util")

return {
  name = "claudecode.nvim",
  dir = util.vendor("claudecode.nvim"),
  dependencies = {
    "snacks.nvim",
  },
  keys = {
    {
      "<F2>",
      "<cmd>ClaudeCode<cr>",
      desc = "Toggle Claude",
      mode = "n",
      silent = true,
    },
    {
      "<F2>",
      [[<C-\><C-n><cmd>ClaudeCode<cr>]],
      desc = "Toggle Claude",
      mode = "t",
      silent = true,
    },
    {
      "<leader>ac",
      "<cmd>ClaudeCode<cr>",
      desc = "Toggle Claude",
      mode = "n",
      silent = true,
    },
    {
      "<leader>af",
      "<cmd>ClaudeCodeFocus<cr>",
      desc = "Focus Claude",
      mode = "n",
      silent = true,
    },
    {
      "<leader>ar",
      "<cmd>ClaudeCode --resume<cr>",
      desc = "Resume Claude",
      mode = "n",
      silent = true,
    },
    {
      "<leader>aC",
      "<cmd>ClaudeCode --continue<cr>",
      desc = "Continue Claude",
      mode = "n",
      silent = true,
    },
    {
      "<leader>am",
      "<cmd>ClaudeCodeSelectModel<cr>",
      desc = "Select Claude model",
      mode = "n",
      silent = true,
    },
    {
      "<leader>ab",
      "<cmd>ClaudeCodeAdd %<cr>",
      desc = "Add current buffer",
      mode = "n",
      silent = true,
    },
    {
      "<leader>as",
      "<cmd>ClaudeCodeSend<cr>",
      desc = "Send to Claude",
      mode = "v",
      silent = true,
    },
    {
      "<leader>aa",
      "<cmd>ClaudeCodeDiffAccept<cr>",
      desc = "Accept diff",
      mode = "n",
      silent = true,
    },
    {
      "<leader>ad",
      "<cmd>ClaudeCodeDiffDeny<cr>",
      desc = "Deny diff",
      mode = "n",
      silent = true,
    },
  },
  config = function()
    local ok, claudecode = pcall(require, "claudecode")
    if not ok then
      return
    end

    if type(claudecode.setup) == "function" then
      claudecode.setup({})
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      callback = function(args)
        vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", {
          buffer = args.buf,
          silent = true,
          desc = "Add file",
        })
      end,
    })
  end,
}
