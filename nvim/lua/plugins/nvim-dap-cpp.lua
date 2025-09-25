local util = require("config.util")
local tools = require("config.tools")

return {
  name = "nvim-dap-cpp",
  dir = util.repo_root(),
  virtual = true,
  dependencies = { "nvim-dap" },
  ft = { "c", "cpp", "rust" },

  config = function()
    local dap = require("dap")

    local gdb = tools.binary("gdb")
    if not gdb then
      vim.notify(
        "nvim-pro-kit: GDB not found on PATH. Set NVIM_PRO_KIT_GDB or install gdb to enable native debugging.",
        vim.log.levels.WARN
      )
    end

    -- 1) Adapter: wire up the built-in GDB DAP interface
    local adapter = {
      type = "executable",
      command = gdb or "gdb",
      args = { "--quiet", "--interpreter=dap" },
      name = "gdb",
    }

    dap.adapters.gdb = adapter
    dap.adapters.cpp = adapter

    -- 2) 针对 C/C++/Rust 的配置
    local function pick_exe()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end

    dap.configurations.c = {
      {
        name = '(gdb) Launch',
        type = "gdb",
        request = "launch",
        program = pick_exe,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
      },
      {
        name = '(gdb) Attach to process',
        type = "gdb",
        request = "attach",
        processId = require('dap.utils').pick_process,
      },
    }

    dap.configurations.cpp  = dap.configurations.c
    dap.configurations.rust = dap.configurations.c
  end,
}
