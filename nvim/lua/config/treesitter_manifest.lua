local util = require("config.util")

local M = {}

local function warn(message)
  if vim.notify then
    vim.schedule(function()
      vim.notify(message, vim.log.levels.WARN, { title = "Tree-sitter" })
    end)
  end
end

local trim = vim.trim or function(str)
  return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function manifest_path()
  local root = util.repo_root()
  if not root then
    return nil
  end
  return vim.fs.normalize(root .. "/scripts/treesitter-parsers.txt")
end

local function parse_lines(lines)
  local languages = {}
  for _, line in ipairs(lines) do
    local trimmed = line:gsub("#.*", "")
    trimmed = trim(trimmed)
    if trimmed ~= "" then
      table.insert(languages, trimmed)
    end
  end
  return languages
end

function M.path()
  return manifest_path()
end

function M.languages(opts)
  opts = opts or {}
  local path = manifest_path()
  if not path or vim.fn.filereadable(path) == 0 then
    if not opts.silent then
      warn(string.format("Tree-sitter manifest not found at %s", path or "<unknown>"))
    end
    return {}
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    if not opts.silent then
      warn(string.format("Failed to read Tree-sitter manifest at %s: %s", path, lines))
    end
    return {}
  end

  local languages = parse_lines(lines)
  if #languages == 0 and not opts.silent then
    warn(string.format("Tree-sitter manifest at %s does not list any parsers", path))
  end
  return languages
end

return M
