local util = require("config.util")

local uv = vim.uv or vim.loop

local function dir_exists(path)
  if not path or path == "" then
    return false
  end
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function macro_recording()
  local register = vim.fn.reg_recording()
  if register ~= "" then
    return "  " .. register
  end
  local executing = vim.fn.reg_executing()
  if executing ~= "" then
    return "  " .. executing
  end
  return ""
end

local function lsp_attached()
  local buf = vim.api.nvim_get_current_buf()
  local clients = {}
  if vim.lsp and vim.lsp.get_clients then
    clients = vim.lsp.get_clients({ bufnr = buf })
  elseif vim.lsp and vim.lsp.get_active_clients then
    clients = vim.lsp.get_active_clients({ bufnr = buf })
  end

  if not clients or vim.tbl_isempty(clients) then
    return ""
  end

  local names = {}
  for _, client in ipairs(clients) do
    if client.name and client.name ~= "" then
      table.insert(names, client.name)
    end
  end

  if vim.tbl_isempty(names) then
    return ""
  end

  return "  " .. table.concat(names, ", ")
end

local function format_mode(mode)
  return "  " .. mode
end

local function diagnostics_component()
  return {
    "diagnostics",
    symbols = { error = "  ", warn = "  ", info = "  ", hint = "  " },
    update_in_insert = false,
  }
end

local function diff_component()
  return {
    "diff",
    symbols = { added = "  ", modified = "  ", removed = "  " },
    padding = { left = 0, right = 1 },
  }
end

local spec = {
  name = "lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-web-devicons",
  },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    local function lazy_updates()
      return lazy_status.updates()
    end

    local function has_lazy_updates()
      return lazy_status.has_updates()
    end

    lualine.setup({
      options = {
        theme = "onedark",
        icons_enabled = true,
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
          statusline = { "alpha", "dashboard" },
          winbar = {},
        },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = {
          { "mode", fmt = format_mode },
        },
        lualine_b = {
          { "branch", icon = "" },
          diff_component(),
          diagnostics_component(),
        },
        lualine_c = {
          {
            "filename",
            path = 1,
            symbols = { modified = " ", readonly = " ", unnamed = "" },
          },
        },
        lualine_x = {
          { lazy_updates, cond = has_lazy_updates, color = { fg = "#89b4fa" } },
          {
            macro_recording,
            cond = function()
              return vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= ""
            end,
          },
          { lsp_attached },
          { "encoding" },
          { "fileformat", icons_enabled = true, fmt = string.upper },
          { "filetype" },
        },
        lualine_y = {
          { "progress" },
        },
        lualine_z = {
          { "location", icon = "" },
        },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            "filename",
            path = 1,
          },
        },
        lualine_x = {
          { "location" },
        },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      extensions = { "quickfix", "nvim-tree", "toggleterm", "fugitive" },
    })
  end,
}

local vendor_dir = util.vendor("lualine.nvim")
if dir_exists(vendor_dir) then
  spec.dir = vendor_dir
else
  spec.url = "https://github.com/nvim-lualine/lualine.nvim"
  spec.branch = "master"
end

return spec
