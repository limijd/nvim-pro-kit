local util = require("config.util")

local M = {}

local uv = vim.uv or vim.loop

local function dir_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function file_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "file"
end

local metadata_cache
local metadata_root

local function metadata_path()
  local root = util.repo_root()
  if not root then
    return nil
  end
  local base = vim.fs.normalize(root .. "/vendor/tree-sitter")
  if not dir_exists(base) then
    return nil
  end
  return base
end

local function normalize_nil(value)
  if value == vim.NIL then
    return nil
  end
  return value
end

local function load_metadata()
  if metadata_cache ~= nil then
    return metadata_cache, metadata_root
  end

  local base = metadata_path()
  if not base then
    metadata_cache = {}
    metadata_root = nil
    return metadata_cache, metadata_root
  end

  local path = base .. "/metadata.json"
  if not file_exists(path) then
    metadata_cache = {}
    metadata_root = nil
    return metadata_cache, metadata_root
  end

  local ok, content = pcall(vim.fn.readfile, path)
  if not ok then
    metadata_cache = {}
    metadata_root = nil
    return metadata_cache, metadata_root
  end

  local decoded
  if vim.json and vim.json.decode then
    local joined = table.concat(content, "\n")
    local success, result = pcall(vim.json.decode, joined)
    decoded = success and result or {}
  else
    local success, result = pcall(vim.fn.json_decode, content)
    decoded = success and result or {}
  end

  metadata_cache = {}
  metadata_root = base

  if type(decoded) ~= "table" then
    return metadata_cache, metadata_root
  end

  for lang, info in pairs(decoded) do
    if type(info) == "table" then
      local normalized = {}
      for key, value in pairs(info) do
        normalized[key] = normalize_nil(value)
      end
      metadata_cache[lang] = normalized
    end
  end

  return metadata_cache, metadata_root
end

local function values(list)
  local result = {}
  for _, value in ipairs(list) do
    table.insert(result, value)
  end
  return result
end

local function iter_languages(langs, metadata)
  if langs and #langs > 0 then
    return ipairs(langs)
  end

  local keys = {}
  for lang in pairs(metadata) do
    table.insert(keys, lang)
  end
  table.sort(keys)
  return ipairs(keys)
end

function M.apply(langs)
  local metadata, base = load_metadata()
  if not base or not metadata or vim.tbl_isempty(metadata) then
    return
  end

  local parsers = require("nvim-treesitter.parsers").get_parser_configs()
  for _, lang in iter_languages(langs, metadata) do
    local info = metadata[lang]
    local config = parsers[lang]
    if info and config and info.files then
      local install = config.install_info
      local dir = base .. "/" .. lang
      if install and dir_exists(dir) then
        install.url = dir
        install.files = values(info.files)
        install.location = info.location or install.location
        install.branch = info.branch
        install.revision = info.revision
        install.generate_requires_npm = info.generate_requires_npm
        install.requires_generate_from_grammar = info.requires_generate_from_grammar
        install.use_makefile = info.use_makefile
        install.cxx_standard = info.cxx_standard
      end
    end
  end
end

return M
