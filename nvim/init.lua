-- Restore Neovim's default backslash leader before loading plugins
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Apply basic options and keymaps
require("config.options")
require("config.keymaps")

-- Discover external tool locations before loading plugins
require("config.tools").setup()

-- Bootstrap lazy.nvim from the vendored plugins directory and load plugins
require("config.lazy")

-- Apply the default colorscheme after plugins have loaded
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    if vim.g.colors_name ~= "onedark" then
      vim.cmd.colorscheme("onedark")
    end
  end,
})
