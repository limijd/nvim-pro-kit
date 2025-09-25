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

    -- 1) 适配器：直接用 gdb 的 DAP 接口
    dap.adapters.cpp = {
      type = 'executable',
      command = 'gdb',
      args = { '--quiet', '--interpreter=dap' }, -- 关键：启用 DAP
      name = 'gdb'
    }

    -- 2) 针对 C/C++/Rust 的配置
    local function pick_exe()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end

    dap.configurations.c = {
      {
        name = '(gdb) Launch',
        type = 'gdb',
        request = 'launch',
        program = pick_exe,          -- 运行时选择 ./a.out 等
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},                   -- 需要参数时填 { "--flag", "value" }
      },
      {
        name = '(gdb) Attach to process',
        type = 'gdb',
        request = 'attach',
        processId = require('dap.utils').pick_process,
      },
    }

    dap.configurations.cpp  = dap.configurations.c
    dap.configurations.rust = dap.configurations.c
  end,
}
