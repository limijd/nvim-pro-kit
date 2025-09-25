local util = require("config.util")

return {
  name = "nvim-dap-ui",
  dir = util.vendor("nvim-dap-ui"),
  dependencies = {
    "nvim-dap",
    "nvim-nio",
    "nvim-web-devicons",
  },
  event = "VeryLazy",
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    dapui.setup({})

    if vim.fn.exists("+winbar") == 1 then
      local controls = require("dapui.controls")
      local original_controls = controls.controls
      controls.controls = function(is_active)
        local bar = original_controls(is_active)
        local title = "DAP: REPL"
        if not bar:find(title, 1, true) then
          bar = bar .. " | " .. title .. " "
        end
        return bar
      end
      controls.refresh_control_panel()

      local titles = {
        dapui_scopes = "DAP: Scopes",
        dapui_breakpoints = "DAP: Breakpoints",
        dapui_stacks = "DAP: Stacks",
        dapui_watches = "DAP: Watches",
        dapui_repl = "DAP: REPL",
        dapui_console = "DAP: Console",
      }

      local winbar_group = vim.api.nvim_create_augroup("DapUIWinbar", { clear = true })

      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = winbar_group,
        callback = function(event)
          local title = titles[vim.bo[event.buf].filetype]
          if not title or vim.bo[event.buf].filetype == "dapui_repl" then
            return
          end

          pcall(vim.api.nvim_win_set_option, vim.api.nvim_get_current_win(), "winbar", " " .. title .. " ")
        end,
      })
    end

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open({})
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close({})
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close({})
    end

    local map = vim.keymap.set
    local opts = { silent = true }

    map("n", "<leader>du", dapui.toggle, vim.tbl_extend("force", opts, { desc = "DAP Toggle UI" }))
    map("n", "<leader>de", function()
      dapui.eval()
    end, vim.tbl_extend("force", opts, { desc = "DAP Evaluate expression" }))
    map("v", "<leader>de", function()
      dapui.eval(nil, { enter = true })
    end, vim.tbl_extend("force", opts, { desc = "DAP Evaluate selection" }))
  end,
}
