local util = require("config.util")
local tools = require("config.tools")

return {
  name = "telescope.nvim",
  dir = util.vendor("telescope.nvim"),
  cmd = "Telescope",
  dependencies = {
    "plenary.nvim",
    "telescope-fzf-native.nvim",
    "nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        vimgrep_arguments = tools.ripgrep_arguments(),
        prompt_prefix = "  ",
        selection_caret = "  ",
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    })

    pcall(telescope.load_extension, "fzf")

    local builtin = require("telescope.builtin")
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    map("n", "<leader>ff", builtin.git_files, vim.tbl_extend("force", opts, { desc = "Find Git files" }))
    map("n", "<leader>fn", builtin.find_files, vim.tbl_extend("force", opts, { desc = "Find files" }))
    map("n", "<leader>fg", builtin.live_grep, vim.tbl_extend("force", opts, { desc = "Live grep" }))
    map("n", "<leader>fb", builtin.buffers, vim.tbl_extend("force", opts, { desc = "List buffers" }))
    map("n", "<leader>fh", builtin.help_tags, vim.tbl_extend("force", opts, { desc = "Search help tags" }))
  end,
}
