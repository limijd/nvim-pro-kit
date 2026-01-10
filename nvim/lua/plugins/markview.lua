local util = require("config.util")

return {
  name = "markview.nvim",
  dir = util.vendor("markview.nvim"),
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter",
    "nvim-web-devicons",
  },
  config = function()
    require("markview").setup({})
  end,
}
