local M = {}

local uv = vim.uv or vim.loop
local config_root = vim.fn.stdpath("config")

local function dir_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local vendor_root = config_root .. "/vendor/plugins"
if not dir_exists(vendor_root) then
  local repo_vendor = config_root .. "/../vendor/plugins"
  if dir_exists(repo_vendor) then
    vendor_root = repo_vendor
  end
end

function M.vendor(name)
  return vim.fs.normalize(vendor_root .. "/" .. name)
end

return M
