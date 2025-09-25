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

    dap.configurations.cpp = {
      {
        name = "Launch",
        type = "gdb",
        request = "launch",
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        args = {}, -- provide arguments if needed
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = true,
      },
      {
        name = "Select and attach to process",
        type = "gdb",
        request = "attach",
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        pid = function()
          local name = vim.fn.input('Executable name (filter): ')
          return require("dap.utils").pick_process({ filter = name })
        end,
        cwd = '${workspaceFolder}'
      },
      {
        name = 'Attach to gdbserver :1234',
        type = 'gdb',
        request = 'attach',
        target = 'localhost:1234',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}'
      }
    }

    dap.configurations.c = dap.configurations.cpp
    dap.configurations.rust = dap.configurations.cpp

    vim.api.nvim_create_user_command("DapGdb", function(command_opts)
      local provided = command_opts.fargs
      if #provided == 0 then
        vim.notify("DapGdb requires an executable path", vim.log.levels.ERROR)
        return
      end

      local args = vim.deepcopy(provided)
      local executable = table.remove(args, 1)

      dap.run({
        name = string.format("GDB: %s", executable),
        type = "gdb",
        request = "launch",
        program = vim.fn.fnamemodify(executable, ":p"),
        args = args,
        cwd = vim.fn.getcwd(),
        stopAtBeginningOfMainSubprogram = true,
      })
    end, { nargs = "+", complete = "file" })

    end,
}
