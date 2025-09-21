local util = require("config.util")

return {
  name = "toggleterm.nvim",
  dir = util.vendor("toggleterm.nvim"),
  cmd = { "ToggleTerm", "TermExec" },
  keys = {
    { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
  },
  config = function()
    require("toggleterm").setup({
      size = 12,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      direction = "float",
      float_opts = {
        border = "curved",
        winblend = 3,
      },
    })

    vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
  end,
}
