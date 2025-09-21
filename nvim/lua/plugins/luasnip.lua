local util = require("config.util")

return {
  name = "LuaSnip",
  dir = util.vendor("LuaSnip"),
  version = "*",
  build = (vim.fn.executable("make") == 1) and "make install_jsregexp" or nil,
  config = function()
    local luasnip = require("luasnip")

    luasnip.config.setup({
      history = true,
      updateevents = "TextChanged,TextChangedI",
      enable_autosnippets = true,
    })

    vim.keymap.set({ "i", "s" }, "<C-j>", function()
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      end
    end, { desc = "Jump to next snippet field" })

    vim.keymap.set({ "i", "s" }, "<C-k>", function()
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      end
    end, { desc = "Jump to previous snippet field" })
  end,
}
