local M = {}

local config_root = vim.fn.stdpath("config")

function M.vendor(name)
  return vim.fs.normalize(config_root .. "/vendor/plugins/" .. name)
end

return M
