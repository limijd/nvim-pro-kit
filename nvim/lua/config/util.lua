local M = {}

local uv = vim.uv or vim.loop
local config_root = vim.fn.stdpath("config")
local resolved_config_root = uv.fs_realpath(config_root) or config_root

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

  local source = debug.getinfo(1, "S")
  source = source and source.source or ""
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end

  if source ~= "" then
    local file_path = uv.fs_realpath(source) or source
    local dir = vim.fs.dirname(file_path)
    while dir and dir ~= "" do
      if vim.fs.basename(dir) == "lua" then
        local parent = vim.fs.dirname(dir)
        if parent and parent ~= "" then
          local maybe_root = vim.fs.dirname(parent)
          if maybe_root and maybe_root ~= "" and dir_exists(maybe_root) then
            return vim.fs.normalize(maybe_root)
          end
        end
        break
      end
      local parent = vim.fs.dirname(dir)
      if not parent or parent == dir then
        break
      end
      dir = parent
    end
  end

  return vim.fs.normalize(resolved_config_root)
end

local repo_root = find_repo_root()

local vendor_root = resolved_config_root .. "/vendor/plugins"
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
