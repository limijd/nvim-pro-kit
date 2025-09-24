local M = {}

local uv = vim.uv or vim.loop
local dir_separator = package.config:sub(1, 1)
local path_separator = package.config:sub(3, 3)

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

local function define(name, resolver)
  local function wrapped()
    if cache[name] == nil then
      cache[name] = resolver()
    end
    return cache[name]
  end
  M[name] = wrapped
  resolvers[name] = wrapped
end

define("git", function()
  return resolve("NVIM_PRO_KIT_GIT", {
    linux_x86_64 = { "/usr/bin/git", "/usr/local/bin/git" },
    linux_aarch64 = { "/usr/bin/git", "/usr/local/bin/git" },
    macos_x86_64 = { "/usr/local/bin/git" },
    macos_arm64 = { "/opt/homebrew/bin/git" },
  }, { "git" })
end)

define("lazygit", function()
  return resolve("NVIM_PRO_KIT_LAZYGIT", {
    linux_x86_64 = { "/usr/bin/lazygit", "/usr/local/bin/lazygit" },
    linux_aarch64 = { "/usr/bin/lazygit", "/usr/local/bin/lazygit" },
    macos_x86_64 = { "/usr/local/bin/lazygit" },
    macos_arm64 = { "/opt/homebrew/bin/lazygit" },
  }, { "lazygit" })
end)

define("ripgrep", function()
  return resolve("NVIM_PRO_KIT_RIPGREP", {
    linux_x86_64 = { "/usr/bin/rg", "/usr/local/bin/rg" },
    linux_aarch64 = { "/usr/bin/rg", "/usr/local/bin/rg" },
    macos_x86_64 = { "/usr/local/bin/rg" },
    macos_arm64 = { "/opt/homebrew/bin/rg" },
  }, { "rg" })
end)

define("python", function()
  return resolve("NVIM_PRO_KIT_PYTHON", {
    linux_x86_64 = { "/usr/bin/python3", "/usr/bin/python" },
    linux_aarch64 = { "/usr/bin/python3", "/usr/bin/python" },
    macos_x86_64 = { "/usr/local/bin/python3", "/usr/bin/python3" },
    macos_arm64 = { "/opt/homebrew/bin/python3", "/usr/bin/python3" },
  }, { "python3", "python" })
end)

define("node", function()
  return resolve("NVIM_PRO_KIT_NODE", {
    linux_x86_64 = { "/usr/bin/node", "/usr/local/bin/node" },
    linux_aarch64 = { "/usr/bin/node", "/usr/local/bin/node" },
    macos_x86_64 = { "/usr/local/bin/node" },
    macos_arm64 = { "/opt/homebrew/bin/node" },
  }, { "node" })
end)

define("npm", function()
  return resolve("NVIM_PRO_KIT_NPM", {
    linux_x86_64 = { "/usr/bin/npm", "/usr/local/bin/npm" },
    linux_aarch64 = { "/usr/bin/npm", "/usr/local/bin/npm" },
    macos_x86_64 = { "/usr/local/bin/npm" },
    macos_arm64 = { "/opt/homebrew/bin/npm" },
  }, { "npm" })
end)

define("tree_sitter", function()
  return resolve("NVIM_PRO_KIT_TREE_SITTER", {
    linux_x86_64 = { "/usr/bin/tree-sitter", "/usr/local/bin/tree-sitter" },
    linux_aarch64 = { "/usr/bin/tree-sitter", "/usr/local/bin/tree-sitter" },
    macos_x86_64 = { "/usr/local/bin/tree-sitter" },
    macos_arm64 = { "/opt/homebrew/bin/tree-sitter" },
  }, { "tree-sitter" })
end)

define("make", function()
  return resolve("NVIM_PRO_KIT_MAKE", {
    linux_x86_64 = { "/usr/bin/make", "/usr/local/bin/make" },
    linux_aarch64 = { "/usr/bin/make", "/usr/local/bin/make" },
    macos_x86_64 = { "/usr/local/bin/gmake", "/usr/bin/make" },
    macos_arm64 = { "/opt/homebrew/bin/gmake", "/usr/bin/make" },
  }, { "gmake", "make" })
end)

define("gdb", function()
  return resolve("NVIM_PRO_KIT_GDB", {
    linux_x86_64 = { "/usr/bin/gdb", "/usr/local/bin/gdb" },
    linux_aarch64 = { "/usr/bin/gdb", "/usr/local/bin/gdb" },
    macos_x86_64 = { "/usr/local/bin/gdb" },
    macos_arm64 = { "/opt/homebrew/bin/gdb" },
  }, { "gdb" })
end)

define("lua_ls", function()
  local mason = mason_tool("lua-language-server")
  return resolve("NVIM_PRO_KIT_LUA_LS", {
    linux_x86_64 = { "/usr/bin/lua-language-server", mason },
    linux_aarch64 = { "/usr/bin/lua-language-server", mason },
    macos_x86_64 = { "/usr/local/bin/lua-language-server", mason },
    macos_arm64 = { "/opt/homebrew/bin/lua-language-server", mason },
  }, { mason, "lua-language-server" })
end)

define("pyright", function()
  local mason = mason_tool("pyright-langserver")
  return resolve("NVIM_PRO_KIT_PYRIGHT", {
    linux_x86_64 = { "/usr/bin/pyright-langserver", "/usr/local/bin/pyright-langserver", mason },
    linux_aarch64 = { "/usr/bin/pyright-langserver", "/usr/local/bin/pyright-langserver", mason },
    macos_x86_64 = { "/usr/local/bin/pyright-langserver", mason },
    macos_arm64 = { "/opt/homebrew/bin/pyright-langserver", mason },
  }, { mason, "pyright-langserver" })
end)

define("ts_ls", function()
  local mason = mason_tool("typescript-language-server")
  return resolve("NVIM_PRO_KIT_TS_LS", {
    linux_x86_64 = { "/usr/bin/typescript-language-server", "/usr/local/bin/typescript-language-server", mason },
    linux_aarch64 = { "/usr/bin/typescript-language-server", "/usr/local/bin/typescript-language-server", mason },
    macos_x86_64 = { "/usr/local/bin/typescript-language-server", mason },
    macos_arm64 = { "/opt/homebrew/bin/typescript-language-server", mason },
  }, { mason, "typescript-language-server" })
end)

define("hg", function()
  return resolve("NVIM_PRO_KIT_HG", {
    linux_x86_64 = { "/usr/bin/hg", "/usr/local/bin/hg" },
    linux_aarch64 = { "/usr/bin/hg", "/usr/local/bin/hg" },
    macos_x86_64 = { "/usr/local/bin/hg" },
    macos_arm64 = { "/opt/homebrew/bin/hg" },
  }, { "hg" })
end)

local lsp_args = {
  lua_ls = {},
  pyright = { "--stdio" },
  ts_ls = { "--stdio" },
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
  return M
end

return M
