local util = require("config.util")

return {
  name = "telescope-fzf-native.nvim",
  dir = util.vendor("telescope-fzf-native.nvim"),
  build = "make",
  cond = function()
    return vim.fn.executable("make") == 1
  end,
}
