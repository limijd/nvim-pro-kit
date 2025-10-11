local util = require("config.util")
local tools = require("config.tools")

return {
  name = "nvim-gdb",
  dir = util.vendor("nvim-gdb"),
  event = "VeryLazy",
  init = function()
    vim.g.nvimgdb_config_override = vim.tbl_deep_extend(
      "force",
      vim.g.nvimgdb_config_override or {},
      {
        termwin_command = "leftabove vnew",
        codewin_command = "belowright vnew",
      }
    )
    tools.gdb()
  end,
}
