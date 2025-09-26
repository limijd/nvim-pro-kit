local util = require("config.util")

local function parse_workspaces(value)
  if not value or value == "" then
    return nil
  end

  local workspaces = {}
  for entry in value:gmatch("[^;,]+") do
    local trimmed = vim.trim(entry)
    if trimmed ~= "" then
      local name, path = trimmed:match("^([^:=]+)[:=](.+)$")
      if path then
        name = vim.trim(name)
        path = vim.trim(path)
      else
        path = trimmed
        name = nil
      end

      local expanded = vim.fn.expand(path)
      if expanded and expanded ~= "" then
        local normalized = vim.fs.normalize(expanded)
        if normalized then
          table.insert(workspaces, {
            name = name and vim.trim(name) ~= "" and name or vim.fs.basename(normalized),
            path = normalized,
          })
        end
      end
    end
  end

  if #workspaces > 0 then
    return workspaces
  end
end

return {
  name = "obsidian.nvim",
  dir = util.vendor("obsidian.nvim"),
  dependencies = {
    "plenary.nvim",
    "nvim-cmp",
    "telescope.nvim",
  },
  ft = { "markdown" },
  cmd = {
    "ObsidianBacklinks",
    "ObsidianExtractNote",
    "ObsidianFollowLink",
    "ObsidianLink",
    "ObsidianLinkNew",
    "ObsidianNew",
    "ObsidianOpen",
    "ObsidianQuickSwitch",
    "ObsidianSearch",
    "ObsidianTemplate",
    "ObsidianToday",
    "ObsidianTomorrow",
    "ObsidianYesterday",
  },
  keys = {
    {
      "<leader>on",
      function()
        vim.cmd.ObsidianNew()
      end,
      desc = "Obsidian new note",
    },
    {
      "<leader>oo",
      function()
        vim.cmd.ObsidianQuickSwitch()
      end,
      desc = "Obsidian quick switch",
    },
    {
      "<leader>os",
      function()
        vim.cmd.ObsidianSearch()
      end,
      desc = "Obsidian search",
    },
  },
  config = function()
    local default_path = vim.env.NVIM_PRO_KIT_OBSIDIAN or vim.env.OBSIDIAN_VAULT or "~/Obsidian"
    local workspace_env = vim.env.NVIM_PRO_KIT_OBSIDIAN_WORKSPACES or vim.env.OBSIDIAN_WORKSPACES

    local workspaces = parse_workspaces(workspace_env)
    if not workspaces then
      local expanded = vim.fn.expand(default_path)
      local normalized = vim.fs.normalize(expanded)
      workspaces = {
        {
          name = "notes",
          path = normalized,
        },
      }
    end

    require("obsidian").setup({
      workspaces = workspaces,
      completion = { nvim_cmp = true },
    })
  end,
}
