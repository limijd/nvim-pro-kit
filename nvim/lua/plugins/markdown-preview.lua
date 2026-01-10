local util = require("config.util")

return {
  name = "markdown-preview.nvim",
  dir = util.vendor("markdown-preview.nvim"),
  ft = { "markdown" },
  cmd = {
    "MarkdownPreview",
    "MarkdownPreviewStop",
    "MarkdownPreviewToggle",
  },
  build = "cd app && npm install",
  config = function()
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_refresh_slow = 0
  end,
}
