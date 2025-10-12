local util = require("config.util")

local function standard_config()
  return {
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
  }
end

local function tmux_config()
  return {
    style = "darker",
    transparent = true,
    term_colors = true,
    code_style = {
      comments = "italic",
      keywords = "bold",
      functions = "italic",
    },
    diagnostics = {
      darker = true,
      undercurl = true,
      background = false,
    },
  }
end

return {
  name = "onedark.nvim",
  dir = util.vendor("onedark.nvim"),
  priority = 1000,
  config = function()
    local config = standard_config()

    if vim.env.TMUX and vim.env.TMUX ~= "" then
      config = tmux_config()
    end

    require("onedark").setup(config)
    require("onedark").load()
  end,
}
