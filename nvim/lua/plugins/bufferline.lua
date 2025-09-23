local util = require("config.util")

local uv = vim.uv or vim.loop

local function dir_exists(path)
  if not path or path == "" then
    return false
  end
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function extend(opts, overrides)
  return vim.tbl_extend("force", opts, overrides)
end

local spec = {
  name = "bufferline.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-web-devicons",
  },
  config = function()
    local bufferline = require("bufferline")

    local severity_icons = {
      error = " ",
      warning = " ",
      info = " ",
      hint = " ",
    }

    bufferline.setup({
      options = {
        mode = "buffers",
        themable = true,
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(_, _, diagnostics_dict)
          for _, severity in ipairs({ "error", "warning", "info", "hint" }) do
            local count = diagnostics_dict[severity]
            if count and count > 0 then
              return severity_icons[severity] .. count
            end
          end
          return ""
        end,
        diagnostics_update_in_insert = false,
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            highlight = "Directory",
            text_align = "left",
            separator = true,
          },
        },
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = "thin",
        always_show_bufferline = false,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },
        sort_by = "insert_after_current",
        indicator = {
          style = "underline",
        },
        numbers = "ordinal",
      },
    })

    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    map("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", extend(opts, { desc = "Next buffer" }))
    map("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", extend(opts, { desc = "Previous buffer" }))
    map("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", extend(opts, { desc = "Pin buffer" }))
    map("n", "<leader>bc", "<cmd>BufferLinePickClose<CR>", extend(opts, { desc = "Pick buffer to close" }))
    map("n", "<leader>bb", "<cmd>BufferLinePick<CR>", extend(opts, { desc = "Jump to buffer" }))
    map("n", "<leader>b[", "<cmd>BufferLineMovePrev<CR>", extend(opts, { desc = "Move buffer left" }))
    map("n", "<leader>b]", "<cmd>BufferLineMoveNext<CR>", extend(opts, { desc = "Move buffer right" }))
    map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", extend(opts, { desc = "Close other buffers" }))
  end,
}

local vendor_dir = util.vendor("bufferline.nvim")
if dir_exists(vendor_dir) then
  spec.dir = vendor_dir
else
  spec.url = "https://github.com/akinsho/bufferline.nvim"
  spec.branch = "main"
end

return spec
