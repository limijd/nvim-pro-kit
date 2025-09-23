local util = require("config.util")

local lazypath = util.vendor("lazy.nvim")
if not vim.loop.fs_stat(lazypath) then
  error("lazy.nvim was not found. Please ensure vendor/plugins/lazy.nvim exists")
end

vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = {
    colorscheme = { "onedark" },
  },
  change_detection = {
    notify = false,
  },
  checker = {
    enabled = false,
  },
  performance = {
    rtp = {
        disabled_plugins = {
          "gzip",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
        },
    },
  },
})
