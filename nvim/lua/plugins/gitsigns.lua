local util = require("config.util")
local tools = require("config.tools")

return {
  name = "gitsigns.nvim",
  dir = util.vendor("gitsigns.nvim"),
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "plenary.nvim",
  },
  config = function()
    local git_binary = tools.git() or "git"

    require("gitsigns").setup({
      git_cmd = { git_binary },
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 700,
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("n", "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(gs.next_hunk)
          return "<Ignore>"
        end, "Next hunk")

        map("n", "[c", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(gs.prev_hunk)
          return "<Ignore>"
        end, "Previous hunk")

        map({ "n", "v" }, "<leader>hs", gs.stage_hunk, "Stage hunk")
        map({ "n", "v" }, "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "Blame line")
      end,
    })
  end,
}
