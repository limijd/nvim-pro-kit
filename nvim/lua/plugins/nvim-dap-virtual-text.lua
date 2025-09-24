local util = require("config.util")

return {
  name = "nvim-dap-virtual-text",
  dir = util.vendor("nvim-dap-virtual-text"),
  dependencies = {
    "nvim-dap",
    "nvim-treesitter",
  },
  event = "VeryLazy",
  config = function()
    require("nvim-dap-virtual-text").setup({
      commented = true,
      highlight_changed_variables = true,
    })
  end,
}
