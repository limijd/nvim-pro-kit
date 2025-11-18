local map = vim.keymap.set
local default_opts = { noremap = true, silent = true }
local obsidian_hide_pattern = [[\(^\|\s\s\)\zs\.\S\+]]
local path_separator = package.config:sub(1, 1)
local obsidian_tree_group = vim.api.nvim_create_augroup("NvimProKitObsidianTree", { clear = true })
local obsidian_tree_state = {
  root = nil,
  winid = nil,
  buffers = {},
  ensuring_window = false,
  prev_list_hide = nil,
  prev_hideflag = nil,
  applied_pattern = nil,
  hide_applied = false,
}

local ensure_obsidian_tree_target_window

local function desired_tree_width()
  local total = vim.o.columns or 0
  if total <= 0 then
    return nil
  end

  local width = math.floor(total / 3)
  if width < 20 then
    width = 20
  elseif width >= total then
    width = total - 1
  end

  return width
end

local function apply_tree_width(tree_win)
  if not tree_win or not vim.api.nvim_win_is_valid(tree_win) then
    return
  end
  local width = desired_tree_width()
  if not width then
    return
  end

  pcall(vim.api.nvim_win_set_width, tree_win, width)
end

vim.api.nvim_create_autocmd("WinClosed", {
  group = obsidian_tree_group,
  callback = function()
    if obsidian_tree_state.root and obsidian_tree_state.winid then
      ensure_obsidian_tree_target_window()
    end
  end,
})

map({ "n", "v" }, "<Space>", "<Nop>", default_opts)

local function normalize_existing_path(path)
  if not path or path == "" then
    return nil
  end
  local ok, normalized = pcall(vim.fs.normalize, path)
  if not ok or not normalized or normalized == "" then
    return nil
  end
  if normalized ~= path_separator then
    normalized = normalized:gsub(path_separator .. "+$", "")
  end
  return normalized
end

local function expand_and_normalize(path)
  if not path or path == "" then
    return nil
  end
  local expanded = vim.fn.expand(path)
  return normalize_existing_path(expanded)
end

local function is_path_within(path, root)
  local normalized_path = normalize_existing_path(path)
  local normalized_root = normalize_existing_path(root)
  if not normalized_path or not normalized_root then
    return false
  end
  if normalized_path == normalized_root then
    return true
  end
  local prefix = normalized_root .. path_separator
  return normalized_path:sub(1, #prefix) == prefix
end

local function fallback_obsidian_root()
  local vault_root = vim.env.NVIM_PRO_KIT_OBSIDIAN or vim.env.OBSIDIAN_VAULT or "~/Obsidian"
  local normalized = expand_and_normalize(vault_root)
  if not normalized or normalized == "" then
    return nil, "Obsidian vault path is empty"
  end

  local stat = vim.loop.fs_stat(normalized)
  if not stat or stat.type ~= "directory" then
    return nil, string.format("Obsidian vault not found: %s", normalized)
  end

  return normalized, nil
end

local function resolve_obsidian_root(bufnr)
  local ok, obsidian = pcall(require, "obsidian")
  if ok then
    local client_ok, client = pcall(obsidian.get_client)
    if client_ok and client then
      local workspace
      if bufnr then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname and bufname ~= "" then
          local dir = vim.fs.dirname(bufname)
          if dir then
            workspace = obsidian.Workspace.get_workspace_for_dir(dir, client.opts.workspaces)
          end
        end
      end
      if not workspace then
        workspace = client.current_workspace
      end
      if not workspace then
        workspace = obsidian.Workspace.get_default_workspace(client.opts.workspaces)
      end
      if workspace then
        local root = normalize_existing_path(tostring(client:vault_root(workspace)))
        if root then
          return root, nil
        end
      end
    end
  end

  return fallback_obsidian_root()
end

local function open_obsidian_note_with(commands, label)
  local buf = vim.api.nvim_get_current_buf()
  local vault_root, err = resolve_obsidian_root(buf)
  if not vault_root then
    vim.notify(err or "Obsidian vault not available", vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  local bufname = vim.api.nvim_buf_get_name(buf)
  if not bufname or bufname == "" then
    vim.notify("No file associated with current buffer", vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  local normalized = normalize_existing_path(vim.fn.fnamemodify(bufname, ":p"))
  if not normalized or normalized == "" then
    vim.notify("Unable to resolve current file path", vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  if not is_path_within(normalized, vault_root) then
    vim.notify("Current file is not inside the Obsidian vault", vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  local stat = vim.loop.fs_stat(normalized)
  if not stat or stat.type ~= "file" then
    vim.notify("Current buffer is not a saved file on disk", vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  if vim.bo[buf].modifiable and vim.bo[buf].modified then
    vim.cmd("silent write")
  end

  local candidates = {}
  if type(commands) == "table" then
    candidates = commands
  elseif type(commands) == "string" then
    candidates = { commands }
  end

  local resolved
  for _, candidate in ipairs(candidates) do
    if type(candidate) == "string" and candidate ~= "" then
      local path = vim.fn.exepath(candidate)
      if path and path ~= "" then
        resolved = path
        break
      elseif vim.fn.executable(candidate) == 1 then
        resolved = candidate
        break
      end
    end
  end

  if not resolved then
    vim.notify(string.format("%s executable not found", label or "Command"), vim.log.levels.ERROR, { title = "keymaps" })
    return
  end

  local job = vim.fn.jobstart({ resolved, normalized }, { detach = true })
  if job <= 0 then
    vim.notify(string.format("Failed to launch %s", label or resolved), vim.log.levels.ERROR, { title = "keymaps" })
  end
end

local function enable_tree_hide()
  if not obsidian_tree_state.hide_applied then
    obsidian_tree_state.prev_list_hide = vim.g.netrw_list_hide
    obsidian_tree_state.prev_hideflag = vim.g.netrw_hide

    local pattern = obsidian_hide_pattern
    local previous = obsidian_tree_state.prev_list_hide
    if previous and previous ~= "" then
      local prev_text = tostring(previous)
      if not prev_text:find(obsidian_hide_pattern, 1, true) then
        pattern = prev_text .. "," .. obsidian_hide_pattern
      else
        pattern = previous
      end
    end
    obsidian_tree_state.applied_pattern = pattern
  end

  vim.g.netrw_list_hide = obsidian_tree_state.applied_pattern
  vim.g.netrw_hide = 1
  obsidian_tree_state.hide_applied = true
end

local function disable_tree_hide()
  if not obsidian_tree_state.hide_applied then
    return
  end

  vim.g.netrw_list_hide = obsidian_tree_state.prev_list_hide

  if obsidian_tree_state.prev_hideflag == nil then
    vim.g.netrw_hide = nil
  else
    vim.g.netrw_hide = obsidian_tree_state.prev_hideflag
  end

  obsidian_tree_state.prev_list_hide = nil
  obsidian_tree_state.prev_hideflag = nil
  obsidian_tree_state.applied_pattern = nil
  obsidian_tree_state.hide_applied = false
end

local function configure_placeholder_window_buffer(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local ok = pcall(vim.api.nvim_buf_set_option, bufnr, "bufhidden", "wipe")
  if not ok then
    return
  end
  pcall(vim.api.nvim_buf_set_option, bufnr, "buftype", "nofile")
  pcall(vim.api.nvim_buf_set_option, bufnr, "swapfile", false)
  pcall(vim.api.nvim_buf_set_option, bufnr, "buflisted", false)
end

ensure_obsidian_tree_target_window = function()
  if obsidian_tree_state.ensuring_window then
    return
  end

  local root = obsidian_tree_state.root
  local tree_win = obsidian_tree_state.winid
  if not root or not tree_win then
    return
  end

  if not vim.api.nvim_win_is_valid(tree_win) then
    obsidian_tree_state.winid = nil
    return
  end

  local tree_buf = vim.api.nvim_win_get_buf(tree_win)
  if not tree_buf or not obsidian_tree_state.buffers[tree_buf] then
    return
  end

  local target = math.max(tonumber(vim.g.netrw_chgwin) or 2, 2)
  local win_count = vim.fn.winnr("$")
  if win_count >= target then
    apply_tree_width(tree_win)
    return
  end

  obsidian_tree_state.ensuring_window = true
  local previous_win = vim.api.nvim_get_current_win()
  local restore_win = previous_win ~= tree_win and vim.api.nvim_win_is_valid(previous_win)

  if previous_win ~= tree_win then
    pcall(vim.api.nvim_set_current_win, tree_win)
  end

  local ok, err = pcall(function()
    local created_window = false
    while vim.fn.winnr("$") < target do
      vim.cmd("keepalt botright vsplit")
      vim.cmd("enew")
      configure_placeholder_window_buffer(vim.api.nvim_get_current_buf())
      if not vim.api.nvim_win_is_valid(tree_win) then
        break
      end
      vim.api.nvim_set_current_win(tree_win)
      created_window = true
    end
    if created_window or vim.fn.winnr("$") <= target then
      apply_tree_width(tree_win)
    end
  end)

  if restore_win and vim.api.nvim_win_is_valid(previous_win) then
    pcall(vim.api.nvim_set_current_win, previous_win)
  end

  obsidian_tree_state.ensuring_window = false

  if not ok then
    vim.schedule(function()
      vim.notify(string.format("Obsidian tree window setup failed: %s", err), vim.log.levels.WARN, { title = "keymaps" })
    end)
  end
end

local function configure_obsidian_tree_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  obsidian_tree_state.buffers[bufnr] = true
  obsidian_tree_state.winid = vim.api.nvim_get_current_win()

  local function refresh_tree_window()
    obsidian_tree_state.winid = vim.api.nvim_get_current_win()
    ensure_obsidian_tree_target_window()
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = obsidian_tree_group,
    buffer = bufnr,
    callback = refresh_tree_window,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    group = obsidian_tree_group,
    buffer = bufnr,
    once = true,
    callback = function(args)
      obsidian_tree_state.buffers[args.buf] = nil
      if not next(obsidian_tree_state.buffers) then
        disable_tree_hide()
        obsidian_tree_state.root = nil
        obsidian_tree_state.winid = nil
      end
    end,
  })
end

local function open_obsidian_tree()
  local normalized, err = resolve_obsidian_root()
  if not normalized then
    vim.notify(err or "Obsidian vault not available", vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  local previous_winsize = vim.g.netrw_winsize
  vim.g.netrw_winsize = 33

  obsidian_tree_state.root = normalized
  enable_tree_hide()
  vim.cmd.lcd({ args = { normalized } })
  vim.cmd.Lexplore({ args = { normalized } })

  local buf = vim.api.nvim_get_current_buf()
  configure_obsidian_tree_buffer(buf)
  ensure_obsidian_tree_target_window()

  vim.schedule(function()
    if previous_winsize == nil then
      vim.g.netrw_winsize = nil
    else
      vim.g.netrw_winsize = previous_winsize
    end
  end)
end

local function open_obsidian_note_in_firefox()
  open_obsidian_note_with("firefox", "Firefox")
end

map("n", "<leader>ov", open_obsidian_tree, vim.tbl_extend("force", default_opts, { desc = "Open Obsidian file tree" }))
map("n", [[\of]], open_obsidian_note_in_firefox, vim.tbl_extend("force", default_opts, { desc = "Open Obsidian note in Firefox" }))

vim.keymap.set('t', [[\tt]], [[<C-\><C-n><cmd>ToggleTerm<CR>]], { noremap = true, silent = true, desc = "Toggle terminal" })

map("n", "<leader>w", "<cmd>w<cr>", vim.tbl_extend("force", default_opts, { desc = "Save file" }))
map("n", "<leader>q", "<cmd>qa<cr>", vim.tbl_extend("force", default_opts, { desc = "Quit Neovim" }))
map("n", "<leader>h", "<cmd>nohlsearch<cr>", vim.tbl_extend("force", default_opts, { desc = "Clear search highlight" }))
map("n", "<leader>bd", "<cmd>bdelete<cr>", vim.tbl_extend("force", default_opts, { desc = "Delete buffer" }))
map("n", "<leader>bn", "<cmd>bnext<cr>", vim.tbl_extend("force", default_opts, { desc = "Next buffer" }))
map("n", "<leader>bp", "<cmd>bprevious<cr>", vim.tbl_extend("force", default_opts, { desc = "Previous buffer" }))

map("n", "<leader>tn", "<cmd>tabnew<cr>", vim.tbl_extend("force", default_opts, { desc = "New tab" }))
map("n", "<leader>to", "<cmd>tabonly<cr>", vim.tbl_extend("force", default_opts, { desc = "Close other tabs" }))
map("n", "<leader>tc", "<cmd>tabclose<cr>", vim.tbl_extend("force", default_opts, { desc = "Close tab" }))
