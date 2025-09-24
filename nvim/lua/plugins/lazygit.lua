local util = require("config.util")

return {
  name = "lazygit.nvim",
  dir = util.vendor("lazygit.nvim"),
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  dependencies = {
    "plenary.nvim",
  },
  config = function()
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    map("n", "<leader>gg", "<cmd>LazyGit<cr>", vim.tbl_extend("force", opts, { desc = "Open Lazygit" }))
    map(
      "n",
      "<leader>gG",
      "<cmd>LazyGitCurrentFile<cr>",
      vim.tbl_extend("force", opts, { desc = "Open Lazygit for current file" })
    )
  end,
}
