local util = require("config.util")
local manifest = require("config.treesitter_manifest")
local vendor = require("config.treesitter_vendor")

return {
  name = "nvim-treesitter",
  dir = util.vendor("nvim-treesitter"),
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local ensure_installed = manifest.languages()
    vendor.apply(ensure_installed)

    require("nvim-treesitter.configs").setup({
      -- Update scripts/treesitter-parsers.txt and run scripts/treesitter-sync.py
      -- to modify this list.
      ensure_installed = ensure_installed,
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
