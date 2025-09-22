local M = {}

local uv = vim.uv or vim.loop
local config_root = vim.fn.stdpath("config")

local function dir_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function find_repo_root()
  local env_root = vim.env.NVIM_PRO_KIT_ROOT or vim.env.TREESITTER_SYNC_ROOT
  if env_root and env_root ~= "" then
    local normalized = vim.fs.normalize(env_root)
    if dir_exists(normalized) then
      return normalized
    end
  end

  local dir = vim.fs.normalize(config_root)
  while dir do
    local git_dir = dir .. "/.git"
    local stat = uv.fs_stat(git_dir)
    if stat then
      return dir
    end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
  return vim.fs.normalize(config_root)
end

local repo_root = find_repo_root()

local vendor_root = config_root .. "/vendor/plugins"
if not dir_exists(vendor_root) then
  local repo_vendor = repo_root .. "/vendor/plugins"
  if dir_exists(repo_vendor) then
    vendor_root = repo_vendor
  end
end

function M.vendor(name)
  return vim.fs.normalize(vendor_root .. "/" .. name)
end

function M.repo_root()
  return repo_root
end

return M
