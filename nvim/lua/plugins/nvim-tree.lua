local util = require("config.util")

return {
  name = "nvim-tree.lua",
  dir = util.vendor("nvim-tree.lua"),
  dependencies = {
    "nvim-web-devicons",
  },
  cmd = {
    "NvimTreeToggle",
    "NvimTreeFocus",
    "NvimTreeFindFile",
  },
  keys = {
    {
      "<leader>e",
      function()
        require("nvim-tree.api").tree.toggle({ focus = false })
      end,
      desc = "Toggle file explorer",
    },
  },
  init = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  config = function()
    require("nvim-tree").setup({
      disable_netrw = false,
      hijack_netrw = false,
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      view = {
        width = 35,
      },
    })
  end,
}
