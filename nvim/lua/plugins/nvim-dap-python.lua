local util = require("config.util")
local uv = vim.uv or vim.loop

local function python_path()
  local fn = vim.fn
  local is_windows = fn.has("win32") == 1

  local function venv_python(root)
    if not root or root == "" then
      return nil
    end

    local executable = is_windows and "python.exe" or "python3"
    local subdir = is_windows and "Scripts" or "bin"
    local candidate = vim.fs.joinpath(root, subdir, executable)
    if fn.executable(candidate) == 1 then
      return candidate
    end
  end

  local environment_vars = { "VIRTUAL_ENV", "CONDA_PREFIX", "PYENV_VIRTUALENV" }
  for _, name in ipairs(environment_vars) do
    local from_env = venv_python(vim.env[name])
    if from_env then
      return from_env
    end
  end

  local cwd = (uv and uv.cwd and uv.cwd()) or fn.getcwd()
  if cwd and cwd ~= "" then
    local workspace_roots = { ".venv", "venv", ".env" }
    for _, root in ipairs(workspace_roots) do
      local from_workspace = venv_python(vim.fs.joinpath(cwd, root))
      if from_workspace then
        return from_workspace
      end
    end
  end

  local executable = fn.exepath("python3")
  if executable and executable ~= "" then
    return executable
  end

  executable = fn.exepath("python")
  if executable and executable ~= "" then
    return executable
  end

  return is_windows and "python.exe" or "python3"
end

return {
  name = "nvim-dap-python",
  dir = util.vendor("nvim-dap-python"),
  dependencies = { "nvim-dap" },
  ft = "python",
  config = function()
    local dap_python = require("dap-python")

    dap_python.setup(python_path())

    local map = vim.keymap.set
    local opts = { silent = true }

    map("n", "<leader>dn", function()
      dap_python.test_method()
    end, vim.tbl_extend("force", opts, { desc = "DAP Test nearest" }))
    map("n", "<leader>dN", function()
      dap_python.test_class()
    end, vim.tbl_extend("force", opts, { desc = "DAP Test class" }))
    map("v", "<leader>ds", function()
      dap_python.debug_selection()
    end, vim.tbl_extend("force", opts, { desc = "DAP Debug selection" }))
  end,
}
