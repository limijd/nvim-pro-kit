local util = require("config.util")
local tools = require("config.tools")

return {
  name = "telescope-fzf-native.nvim",
  dir = util.vendor("telescope-fzf-native.nvim"),
  build = function(plugin)
    local ok, message = tools.run("make", nil, plugin.dir)
    if not ok then
      vim.notify("telescope-fzf-native build failed: " .. (message or "unknown error"), vim.log.levels.WARN)
    end
  end,
  cond = function()
    return tools.has("make")
  end,
}
