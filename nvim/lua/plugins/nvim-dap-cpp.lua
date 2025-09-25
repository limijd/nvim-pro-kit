local util = require("config.util")
local tools = require("config.tools")

return {
  name = "nvim-dap-cpp",
  dir = util.repo_root(),
  virtual = true,
  dependencies = { "nvim-dap" },
  cmd = { "DapGdb" },
  event = "VeryLazy",

  config = function()
    local dap = require("dap")
    local uv = vim.uv or vim.loop

    local gdb = tools.binary("gdb")
    if not gdb then
      vim.notify(
        "nvim-pro-kit: GDB not found on PATH. Set NVIM_PRO_KIT_GDB or install gdb to enable native debugging.",
        vim.log.levels.WARN
      )
    end

    local function notify(message, level)
      level = level or vim.log.levels.ERROR
      if vim.notify then
        vim.notify(message, level, { title = "nvim-pro-kit" })
        return
      end

      vim.api.nvim_echo({ { message, "" } }, false, {})
    end

    local function resolve_launch_config(program)
      local candidates = dap.configurations.cpp or dap.configurations.c or {}
      local template = candidates[1]

      if template then
        local configuration = vim.deepcopy(template)
        configuration.program = program
        return configuration
      end

      return {
        name = "(gdb) Launch",
        type = "gdb",
        request = "launch",
        program = program,
        cwd = vim.fn.getcwd(),
        stopOnEntry = true,
        args = {},
      }
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
        stopOnEntry = true,
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

    pcall(vim.api.nvim_create_user_command, "DapGdb", function(opts)
      if not gdb then
        notify("nvim-pro-kit: GDB is not available (set NVIM_PRO_KIT_GDB or install gdb).")
        return
      end

      local expanded = vim.fn.expand(opts.args)
      if expanded == "" then
        notify("nvim-pro-kit: Provide a path to an executable, e.g. :DapGdb ./a.out")
        return
      end

      local program = vim.fn.fnamemodify(expanded, ":p")
      local stat = uv.fs_stat(program)
      if not stat or stat.type ~= "file" then
        notify(string.format("nvim-pro-kit: '%s' is not a valid executable file.", program))
        return
      end

      if vim.fn.executable(program) ~= 1 then
        notify(string.format("nvim-pro-kit: '%s' is not marked as executable.", program))
        return
      end

      dap.run(resolve_launch_config(program))
    end, {
      nargs = 1,
      complete = "file",
      desc = "Debug an executable with GDB via nvim-dap",
    })
  end,
}
