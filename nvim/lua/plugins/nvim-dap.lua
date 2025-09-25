local util = require("config.util")

return {
  name = "nvim-dap",
  dir = util.vendor("nvim-dap"),
  event = "VeryLazy",
  config = function()
    local dap = require("dap")

    local sign = vim.fn.sign_define
    sign("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
    sign("DapBreakpointCondition", { text = "", texthl = "DiagnosticSignWarn", linehl = "", numhl = "" })
    sign("DapBreakpointRejected", { text = "", texthl = "DiagnosticSignHint", linehl = "", numhl = "" })
    sign("DapStopped", { text = "", texthl = "DiagnosticSignInfo", linehl = "DiagnosticUnderlineInfo", numhl = "" })

    local map = vim.keymap.set
    local opts = { silent = true }

    local function continue()
      local session = dap.session()
      if session then
        dap.continue()
        return
      end

      local ft = vim.bo.filetype
      local configs = dap.configurations[ft]
      if configs and #configs > 0 then
        dap.continue()
        return
      end

      local entries = {}
      for language, language_configs in pairs(dap.configurations) do
        for _, cfg in ipairs(language_configs) do
          table.insert(entries, {
            label = string.format("%s: %s", language, cfg.name or "<unnamed>"),
            config = vim.deepcopy(cfg),
          })
        end
      end

      if vim.tbl_isempty(entries) then
        vim.notify("nvim-pro-kit: No debug configurations available.", vim.log.levels.ERROR)
        return
      end

      vim.ui.select(entries, {
        prompt = "Select debug configuration",
        format_item = function(item)
          return item.label
        end,
      }, function(choice)
        if choice then
          dap.run(choice.config)
        end
      end)
    end

    map("n", "<F5>", continue, vim.tbl_extend("force", opts, { desc = "DAP Continue" }))
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

  end,
}
