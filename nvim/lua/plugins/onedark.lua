local util = require("config.util")

return {
  {
    name = "onedark.nvim",
    dir = util.vendor("onedark.nvim"),
    priority = 1000,
    config = function()
      require("onedark").setup({
        style = "darker",
        term_colors = true,
        transparent = true,
        highlights = {
          Comment = { fg = "#7F848E" }, -- 不设 bg，不设 italic
        },
      })

      require("onedark").load()

      local in_tmux = vim.env.TMUX ~= nil

      local function fix_comment()
        vim.api.nvim_set_hl(0, "Comment", {
          fg = "#7F848E",
          italic = not in_tmux,
        })
        vim.api.nvim_set_hl(0, "@comment", { link = "Comment" })
      end

      fix_comment()

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = fix_comment,
      })
    end,
  },
}
