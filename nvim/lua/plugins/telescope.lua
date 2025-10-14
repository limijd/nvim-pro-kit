local util = require("config.util")
local tools = require("config.tools")

return {
  name = "telescope.nvim",
  dir = util.vendor("telescope.nvim"),
  cmd = "Telescope",
  keys = {
    {
      "<leader>ff",
      function()
        require("telescope.builtin").git_files()
      end,
      desc = "Find Git files",
      mode = "n",
      silent = true,
    },
    {
      "<leader>fn",
      function()
        require("telescope.builtin").find_files()
      end,
      desc = "Find files",
      mode = "n",
      silent = true,
    },
    {
      "<leader>fg",
      function()
        require("telescope.builtin").live_grep()
      end,
      desc = "Live grep",
      mode = "n",
      silent = true,
    },
    {
      "<leader>fb",
      function()
        require("telescope.builtin").buffers()
      end,
      desc = "List buffers",
      mode = "n",
      silent = true,
    },
    {
      "<leader>fh",
      function()
        require("telescope.builtin").help_tags()
      end,
      desc = "Search help tags",
      mode = "n",
      silent = true,
    },
  },
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
        -- path_display = { "smart" },
        path_display = { "relative" },
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

  end,
}
