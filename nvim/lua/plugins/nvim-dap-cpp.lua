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

    local gdb = tools.binary("gdb") or "gdb"

    dap.adapters.gdb = {
      type = "executable",
      command = gdb,
      args = { "-i", "dap" },
    }

    dap.adapters.cpp = dap.adapters.gdb

    local function pick_executable()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end

    local function base_launch_config()
      return {
        name = "(gdb) Launch",
        type = "gdb",
        request = "launch",
        cwd = "${workspaceFolder}",
        stopOnEntry = true,
        stopAtEntry = true,
        args = {},
      }
    end

    dap.configurations.c = {
      vim.tbl_extend("force", base_launch_config(), { program = pick_executable }),
      {
        name = "(gdb) Attach to process",
        type = "gdb",
        request = "attach",
        processId = require("dap.utils").pick_process,
      },
    }

    dap.configurations.cpp = dap.configurations.c
    dap.configurations.rust = dap.configurations.c

    pcall(vim.api.nvim_create_user_command, "DapGdb", function(opts)
      local program = opts.args
      if program == "" then
        program = pick_executable()
      else
        program = vim.fn.fnamemodify(vim.fn.expand(program), ":p")
      end

      if not program or program == "" then
        return
      end

      local launch = base_launch_config()
      launch.program = program
      launch.cwd = vim.fn.getcwd()
      dap.run(launch)
    end, {
      nargs = "?",
      complete = "file",
      desc = "Debug an executable with GDB via nvim-dap",
    })
  end,
}
