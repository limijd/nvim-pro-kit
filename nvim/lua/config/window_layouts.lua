local M = {}

local api = vim.api

local function is_normal_window(win)
  local ok, cfg = pcall(api.nvim_win_get_config, win)
  return ok and cfg and (cfg.relative == nil or cfg.relative == "")
end

local function create_even_grid(total)
  if type(total) ~= "number" or total < 2 or (total % 2) ~= 0 then
    vim.notify("Window layout must be an even number >= 2", vim.log.levels.ERROR, { title = "window_layouts" })
    return
  end

  local cols = math.floor(total / 2)
  if cols < 1 then
    return
  end

  local ok, err = pcall(vim.cmd, "only")
  if not ok then
    vim.notify(
      "Unable to close existing windows (save changes or enable 'hidden')",
      vim.log.levels.WARN,
      { title = "window_layouts" }
    )
    if err and type(err) == "string" and err ~= "" then
      vim.notify(err, vim.log.levels.DEBUG, { title = "window_layouts" })
    end
    return
  end

  for _ = 2, cols do
    vim.cmd("vsplit")
  end

  local wins = api.nvim_tabpage_list_wins(0)
  local targets = {}
  for _, win in ipairs(wins) do
    if api.nvim_win_is_valid(win) and is_normal_window(win) then
      table.insert(targets, win)
    end
  end

  for _, win in ipairs(targets) do
    if api.nvim_win_is_valid(win) then
      api.nvim_set_current_win(win)
      vim.cmd("split")
    end
  end

  vim.cmd("wincmd =")
  vim.cmd("wincmd t")
end

local function cabbrev(cmd, replacement)
  vim.cmd(string.format(
    "cnoreabbrev <expr> %s (getcmdtype() == ':' && getcmdline() == '%s') ? '%s' : '%s'",
    cmd,
    cmd,
    replacement,
    cmd
  ))
end

function M.setup()
  api.nvim_create_user_command("Win4", function()
    create_even_grid(4)
  end, { desc = "Create 2x2 split grid (4 windows)" })

  api.nvim_create_user_command("Win6", function()
    create_even_grid(6)
  end, { desc = "Create 3x2 split grid (6 windows)" })

  api.nvim_create_user_command("Win8", function()
    create_even_grid(8)
  end, { desc = "Create 4x2 split grid (8 windows)" })

  -- Allow typing :win4/:win6/:win8 in the command-line (user commands must be capitalized).
  cabbrev("win4", "Win4")
  cabbrev("win6", "Win6")
  cabbrev("win8", "Win8")
end

return M
