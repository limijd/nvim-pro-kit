local util = require("config.util")

return {
  name = "claudecode.nvim",
  dir = util.vendor("claudecode.nvim"),
  config = function()
    local ok, claudecode = pcall(require, "claudecode")
    if not ok then
      return
    end

    if type(claudecode.setup) == "function" then
      claudecode.setup({})
    end
  end,
}
