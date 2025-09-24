local util = require("config.util")
local tools = require("config.tools")

return {
  name = "nvim-gdb",
  dir = util.vendor("nvim-gdb"),
  event = "VeryLazy",
  init = function()
    tools.gdb()
  end,
}
