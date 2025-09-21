local util = require("config.util")

return {
  name = "nvim-treesitter",
  dir = util.vendor("nvim-treesitter"),
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "bash",
        "lua",
        "vim",
        "vimdoc",
        "json",
        "python",
        "javascript",
        "typescript",
      },
      auto_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<c-space>",
          node_incremental = "<c-space>",
          node_decremental = "<c-backspace>",
          scope_incremental = "<c-s>",
        },
      },
    })
  end,
}
