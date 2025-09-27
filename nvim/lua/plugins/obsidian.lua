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

local function filter_existing_workspaces(workspaces)
  if not workspaces then
    return {}, {}
  end

  local valid, missing = {}, {}
  for _, workspace in ipairs(workspaces) do
    local stat = vim.loop.fs_stat(workspace.path)
    if stat and stat.type == "directory" then
      table.insert(valid, workspace)
    else
      table.insert(missing, workspace)
    end
  end

  return valid, missing
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

    local existing, missing = filter_existing_workspaces(workspaces)

    if #missing > 0 then
      local lines = { "obsidian.nvim workspaces not found:" }
      for _, workspace in ipairs(missing) do
        local label = workspace.name and (workspace.name .. " → ") or ""
        table.insert(lines, string.format("  • %s%s", label, workspace.path))
      end

      table.insert(lines, "Configure NVIM_PRO_KIT_OBSIDIAN or NVIM_PRO_KIT_OBSIDIAN_WORKSPACES to silence this warning.")

      vim.schedule(function()
        vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN, { title = "obsidian.nvim" })
      end)
    end

    if #existing == 0 then
      vim.schedule(function()
        vim.notify(
          "obsidian.nvim disabled because no workspace directories exist.\n" ..
            "Set NVIM_PRO_KIT_OBSIDIAN or NVIM_PRO_KIT_OBSIDIAN_WORKSPACES to configure one.",
          vim.log.levels.WARN,
          { title = "obsidian.nvim" }
        )
      end)

      return
    end

    require("obsidian").setup({
      workspaces = existing,
      completion = { nvim_cmp = true },
    })
  end,
}
