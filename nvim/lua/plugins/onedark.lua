local util = require("config.util")

return {
  name = "onedark.nvim",
  dir = util.vendor("onedark.nvim"),
  priority = 1000,
  config = function()
    require("onedark").setup({
      style = "warmer",
      transparent = false,
      term_colors = true,
      code_style = {
        comments = "italic",
        keywords = "bold",
        functions = "italic",
      },
      diagnostics = {
        darker = true,
        undercurl = true,
        background = true,
      },
    })
    require("onedark").load()
  end,
}
