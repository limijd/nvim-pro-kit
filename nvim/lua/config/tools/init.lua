local M = {}

local api = vim.api
local uv = vim.uv or vim.loop
local util = require("config.util")
local dir_separator = package.config:sub(1, 1)
local path_separator = package.config:sub(3, 3)
local repo_root = util.repo_root()

local function detect_platform()
  local uname = (uv and uv.os_uname and uv.os_uname()) or {}
  local sysname = (uname.sysname or ""):lower()
  local machine = (uname.machine or ""):lower()

  if sysname:find("linux") then
    if machine == "x86_64" or machine == "amd64" then
      return "linux_x86_64"
    elseif machine == "aarch64" or machine == "arm64" then
      return "linux_aarch64"
    end
    return "linux"
  elseif sysname:find("darwin") then
    if machine == "x86_64" then
      return "macos_x86_64"
    elseif machine == "arm64" then
      return "macos_arm64"
    end
    return "macos"
  end

  return "unknown"
end

local platform = detect_platform()

local function mason_tool(name)
  local base = vim.fn.stdpath("data")
  if not base or base == "" then
    return nil
  end
  return vim.fs.normalize(base .. "/mason/bin/" .. name)
end

local function ensure_dir_on_path(path)
  if not path or path == "" then
    return
  end

  if not path:find(dir_separator, 1, true) then
    return
  end

  local dir = vim.fs.dirname(path)
  if not dir or dir == "" then
    return
  end

  local current = vim.env.PATH or ""
  for entry in string.gmatch(current, "[^" .. path_separator .. "]+") do
    if entry == dir then
      return
    end
  end

  if current == "" then
    vim.env.PATH = dir
  else
    vim.env.PATH = dir .. path_separator .. current
  end
end

local function normalize(candidate)
  if not candidate or candidate == "" then
    return nil
  end

  local expanded = vim.fn.expand(candidate)
  if expanded:find(dir_separator, 1, true) then
    if vim.fn.executable(expanded) == 1 then
      return vim.fs.normalize(expanded)
    end
    return nil
  end

  local resolved = vim.fn.exepath(expanded)
  if resolved and resolved ~= "" then
    return resolved
  end
end

local function extend(list, value)
  if not value then
    return
  end
  if type(value) == "string" then
    table.insert(list, value)
  elseif type(value) == "table" then
    for _, item in ipairs(value) do
      if item and item ~= "" then
        table.insert(list, item)
      end
    end
  end
end

local function resolve(env_name, platform_candidates, fallback)
  local env_value = vim.env[env_name]
  local env_path = normalize(env_value)
  if env_path then
    ensure_dir_on_path(env_path)
    return env_path
  end

  local candidates = {}

  if type(platform_candidates) == "table" then
    extend(candidates, platform_candidates[platform])
    extend(candidates, platform_candidates.default)
  elseif type(platform_candidates) == "string" then
    extend(candidates, platform_candidates)
  end

  extend(candidates, fallback)

  for _, candidate in ipairs(candidates) do
    local resolved = normalize(candidate)
    if resolved then
      ensure_dir_on_path(resolved)
      return resolved
    end
  end

  return nil
end

local cache = {}
local resolvers = {}
local documentation = {}

local function define(name, resolver, doc)
  local function wrapped()
    if cache[name] == nil then
      cache[name] = resolver()
    end
    return cache[name]
  end

  M[name] = wrapped
  resolvers[name] = wrapped
  if doc then
    documentation[name] = doc
  end
end

require("config.tools.definitions")({
  define = define,
  resolve = resolve,
  mason_tool = mason_tool,
  repo_root = repo_root,
})

local lsp_args = {
  lua_ls = {},
  pyright = { "--stdio" },
  ts_ls = { "--stdio" },
  clangd = {
    "--background-index",
    "--background-index-priority=background",
    "--clang-tidy",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--limit-results=50",
    "--malloc-trim",
    "-j=1",
  },
}

function M.binary(tool)
  local resolver = resolvers[tool]
  if not resolver then
    return nil
  end
  return resolver()
end

function M.has(tool)
  return M.binary(tool) ~= nil
end

function M.ensure_on_path(tool)
  return M.binary(tool)
end

function M.paths()
  local names = vim.tbl_keys(resolvers)
  table.sort(names)

  local result = {}
  local missing = {}
  for _, name in ipairs(names) do
    local path = resolvers[name]()
    if path then
      result[name] = path
    else
      result[name] = false
      table.insert(missing, name)
    end
  end

  return result, missing
end

function M.lsp_cmd(server)
  local binary = M.binary(server)
  if not binary then
    return nil
  end

  local cmd = { binary }
  for _, arg in ipairs(lsp_args[server] or {}) do
    table.insert(cmd, arg)
  end
  return cmd
end

function M.python()
  return resolvers.python()
end

function M.ripgrep_arguments()
  local rg = M.ripgrep() or "rg"
  return {
    rg,
    "--color=never",
    "--no-heading",
    "--with-filename",
    "--line-number",
    "--column",
    "--smart-case",
  }
end

function M.compilers()
  local env = vim.env.NVIM_PRO_KIT_COMPILERS
  if env and env ~= "" then
    local list = vim.split(env, path_separator, { trimempty = true })
    local resolved = {}
    for _, entry in ipairs(list) do
      local candidate = normalize(entry)
      table.insert(resolved, candidate or entry)
    end
    if #resolved > 0 then
      return resolved
    end
  end

  local defaults = {
    linux_x86_64 = { "cc", "gcc", "clang" },
    linux_aarch64 = { "cc", "gcc", "clang" },
    macos_x86_64 = { "clang", "cc" },
    macos_arm64 = { "clang", "cc" },
  }

  local candidates = defaults[platform] or { "cc", "gcc", "clang" }
  local resolved = {}
  for _, candidate in ipairs(candidates) do
    local path = normalize(candidate)
    table.insert(resolved, path or candidate)
  end

  return resolved
end

function M.run(tool, args, cwd)
  local binary = M.binary(tool)
  if not binary then
    return false, string.format("Tool '%s' is not available", tool)
  end

  local command = { binary }
  if args and #args > 0 then
    vim.list_extend(command, args)
  end

  if vim.system then
    local result = vim.system(command, { cwd = cwd }):wait()
    local success = result.code == 0
    local stderr = result.stderr or ""
    local stdout = result.stdout or ""
    local message = stderr ~= "" and stderr or stdout
    return success, message
  end

  local output = vim.fn.system(command)
  local success = vim.v.shell_error == 0
  return success, output
end

function M.setup()
  for _, resolver in pairs(resolvers) do
    resolver()
  end
  M.compilers()

  pcall(api.nvim_create_user_command, "Tools", function()
    local paths, missing = M.paths()
    local names = vim.tbl_keys(paths)
    table.sort(names)

    local padding = 0
    for _, name in ipairs(names) do
      padding = math.max(padding, #name)
    end
    if padding == 0 then
      padding = 1
    end

    local lines = {}
    for _, name in ipairs(names) do
      local path = paths[name]
      if path then
        table.insert(lines, string.format("%-" .. padding .. "s  %s", name, path))
      else
        table.insert(lines, string.format("%-" .. padding .. "s  %s", name, "[missing]"))
      end
    end

    local level = (#missing > 0) and vim.log.levels.WARN or vim.log.levels.INFO
    local message = table.concat(lines, "\n")

    if vim.notify then
      vim.notify(message, level, { title = "Tools" })
    else
      for _, line in ipairs(lines) do
        api.nvim_echo({ { line, "" } }, false, {})
      end
    end
  end, {
    desc = "List configured external tools and their resolved paths",
  })
  return M
end

function M.doc(tool)
  return documentation[tool]
end

function M.docs()
  return vim.deepcopy(documentation)
end

return M
