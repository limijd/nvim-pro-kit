local util = require("config.util")
local tools = require("config.tools")

return {
  name = "nvim-dap-python",
  dir = util.vendor("nvim-dap-python"),
  dependencies = { "nvim-dap" },
  ft = "python",
  config = function()
    local dap_python = require("dap-python")

    dap_python.setup(tools.python())

    local map = vim.keymap.set
    local opts = { silent = true }

    map("n", "<leader>dn", function()
      dap_python.test_method()
    end, vim.tbl_extend("force", opts, { desc = "DAP Test nearest" }))
    map("n", "<leader>dN", function()
      dap_python.test_class()
    end, vim.tbl_extend("force", opts, { desc = "DAP Test class" }))
    map("v", "<leader>ds", function()
      dap_python.debug_selection()
    end, vim.tbl_extend("force", opts, { desc = "DAP Debug selection" }))
  end,
}
