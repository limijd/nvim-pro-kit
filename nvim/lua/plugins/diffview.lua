local util = require("config.util")

return {
  name = "diffview.nvim",
  dir = util.vendor("diffview.nvim"),
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggleFiles",
    "DiffviewFileHistory",
  },
  dependencies = {
    "plenary.nvim",
    "nvim-web-devicons",
  },
  config = function()
    local diffview = require("diffview")

    diffview.setup({
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = "diff2_horizontal",
        },
      },
      file_panel = {
        win_config = {
          position = "left",
          width = 35,
        },
      },
    })

    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", vim.tbl_extend("force", opts, { desc = "Open Diffview" }))
    map(
      "n",
      "<leader>gD",
      "<cmd>DiffviewClose<cr>",
      vim.tbl_extend("force", opts, { desc = "Close Diffview" })
    )
    map(
      "n",
      "<leader>gh",
      "<cmd>DiffviewFileHistory %<cr>",
      vim.tbl_extend("force", opts, { desc = "File history" })
    )
    map(
      "n",
      "<leader>gH",
      "<cmd>DiffviewFileHistory<cr>",
      vim.tbl_extend("force", opts, { desc = "Repository history" })
    )
  end,
}
