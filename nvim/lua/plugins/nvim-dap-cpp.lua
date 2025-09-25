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

    dap.adapters.cpp = {
      type = "executable",
      command = gdb or "gdb",
      args = { "--interpreter=dap" },
      name = "gdb",
    }

    local function prompt_program()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end

    local function prompt_arguments()
      local input = vim.fn.input("Program arguments: ")
      if input == nil or input == "" then
        return {}
      end
      return vim.split(input, "%s+", { trimempty = true })
    end

    local function clone_configurations(configs)
      local result = {}
      for _, cfg in ipairs(configs) do
        table.insert(result, vim.deepcopy(cfg))
      end
      return result
    end

    local configurations = {
      {
        name = "Launch executable",
        type = "cpp",
        request = "launch",
        program = prompt_program,
        args = prompt_arguments,
        cwd = "${workspaceFolder}",
        stopAtEntry = false,
        setupCommands = {
          {
            text = "-enable-pretty-printing",
            description = "Enable GDB pretty printing",
            ignoreFailures = true,
          },
        },
      },
      {
        name = "Attach to process",
        type = "cpp",
        request = "attach",
        pid = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
      },
    }

    dap.configurations.cpp = configurations
    dap.configurations.c = clone_configurations(configurations)
    dap.configurations.rust = clone_configurations(configurations)
  end,
}
