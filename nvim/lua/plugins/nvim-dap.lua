local util = require("config.util")

return {
  name = "nvim-dap",
  dir = util.vendor("nvim-dap"),
  event = "VeryLazy",
  config = function()
    local dap = require("dap")
    local tools = require("config.tools")

    local sign = vim.fn.sign_define
    sign("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
    sign("DapBreakpointCondition", { text = "", texthl = "DiagnosticSignWarn", linehl = "", numhl = "" })
    sign("DapBreakpointRejected", { text = "", texthl = "DiagnosticSignHint", linehl = "", numhl = "" })
    sign("DapStopped", { text = "", texthl = "DiagnosticSignInfo", linehl = "DiagnosticUnderlineInfo", numhl = "" })

    local map = vim.keymap.set
    local opts = { silent = true }

    map("n", "<F5>", dap.continue, vim.tbl_extend("force", opts, { desc = "DAP Continue" }))
    map("n", "<F6>", dap.restart, vim.tbl_extend("force", opts, { desc = "DAP Restart" }))
    map("n", "<F7>", dap.terminate, vim.tbl_extend("force", opts, { desc = "DAP Terminate" }))
    map("n", "<F10>", dap.step_over, vim.tbl_extend("force", opts, { desc = "DAP Step Over" }))
    map("n", "<F11>", dap.step_into, vim.tbl_extend("force", opts, { desc = "DAP Step Into" }))
    map("n", "<F12>", dap.step_out, vim.tbl_extend("force", opts, { desc = "DAP Step Out" }))

    map("n", "<leader>db", dap.toggle_breakpoint, vim.tbl_extend("force", opts, { desc = "DAP Toggle breakpoint" }))
    map("n", "<leader>dB", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, vim.tbl_extend("force", opts, { desc = "DAP Set conditional breakpoint" }))
    map("n", "<leader>dl", dap.run_last, vim.tbl_extend("force", opts, { desc = "DAP Run last" }))
    map("n", "<leader>dr", dap.repl.toggle, vim.tbl_extend("force", opts, { desc = "DAP Toggle REPL" }))

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
