local util = require("config.util")
local tools = require("config.tools")

return {
  name = "vim-fugitive",
  dir = util.vendor("vim-fugitive"),
  cmd = { "Git", "G", "GBrowse", "Gdiffsplit", "Gvdiffsplit" },
  keys = {
    {
      "<leader>gs",
      function()
        vim.cmd.Git()
      end,
      desc = "Open Fugitive Git status",
    },
  },
  init = function()
    local git_binary = tools.git()
    if git_binary then
      vim.g.fugitive_git_executable = git_binary
    end
  end,
}
