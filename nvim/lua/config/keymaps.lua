local map = vim.keymap.set
local default_opts = { noremap = true, silent = true }
local obsidian_tree_group = vim.api.nvim_create_augroup("NvimProKitObsidianTree", { clear = true })
local obsidian_hide_pattern = [[^\..*]]
local path_separator = package.config:sub(1, 1)

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

local function apply_obsidian_tree_preferences(bufnr)
  local vars = vim.b[bufnr]
  if not vars.npk_obsidian_root then
    return
  end
  if vars.npk_obsidian_active then
    return
  end

  vars.npk_obsidian_active = true
  vars.npk_obsidian_prev_hide = vim.g.netrw_list_hide
  vars.npk_obsidian_prev_hideflag = vim.g.netrw_hide

  local current = vim.g.netrw_list_hide
  if current and current ~= "" then
    if not current:find(obsidian_hide_pattern, 1, true) then
      vim.g.netrw_list_hide = current .. "," .. obsidian_hide_pattern
    end
  else
    vim.g.netrw_list_hide = obsidian_hide_pattern
  end

  vim.g.netrw_hide = 1
end

local function restore_obsidian_tree_preferences(bufnr)
  local vars = vim.b[bufnr]
  if not vars.npk_obsidian_root or not vars.npk_obsidian_active then
    return
  end

  vars.npk_obsidian_active = false

  vim.g.netrw_list_hide = vars.npk_obsidian_prev_hide
  vars.npk_obsidian_prev_hide = nil

  if vars.npk_obsidian_prev_hideflag == nil then
    vim.g.netrw_hide = nil
  else
    vim.g.netrw_hide = vars.npk_obsidian_prev_hideflag
  end
  vars.npk_obsidian_prev_hideflag = nil
end

local function ensure_obsidian_tree_autocmds(bufnr)
  if vim.b[bufnr].npk_obsidian_autocmds then
    return
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = obsidian_tree_group,
    buffer = bufnr,
    callback = function(args)
      apply_obsidian_tree_preferences(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "BufWinLeave", "BufUnload", "BufWipeout" }, {
    group = obsidian_tree_group,
    buffer = bufnr,
    callback = function(args)
      restore_obsidian_tree_preferences(args.buf)
    end,
  })

  vim.b[bufnr].npk_obsidian_autocmds = true
end

local function attach_obsidian_tree_behavior(bufnr, root)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.b[bufnr].npk_obsidian_root = root
  ensure_obsidian_tree_autocmds(bufnr)
  apply_obsidian_tree_preferences(bufnr)
end

local function find_obsidian_tree_buffer(target_dir)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_option(buf, "filetype") == "netrw" then
      if vim.b[buf].npk_obsidian_root and vim.b[buf].npk_obsidian_root == target_dir then
        return buf
      end
      local curdir = vim.b[buf].netrw_curdir
      if curdir and is_path_within(curdir, target_dir) then
        return buf
      end
    end
  end
end

local function open_obsidian_tree()
  local normalized, err = resolve_obsidian_root()
  if not normalized then
    vim.notify(err or "Obsidian vault not available", vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  local previous_winsize = vim.g.netrw_winsize
  vim.g.netrw_winsize = 33

  vim.cmd.lcd({ args = { normalized } })
  vim.cmd.Lexplore({ args = { normalized } })

  local attached = false
  local current_buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_option(current_buf, "filetype") == "netrw" then
    attach_obsidian_tree_behavior(current_buf, normalized)
    attached = true
  end

  if not attached then
    local tree_buf = find_obsidian_tree_buffer(normalized)
    if tree_buf then
      attach_obsidian_tree_behavior(tree_buf, normalized)
      attached = true
    end
  end

  if not attached then
    vim.defer_fn(function()
      local buf = find_obsidian_tree_buffer(normalized)
      if not buf then
        local maybe_current = vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(maybe_current) and vim.api.nvim_buf_get_option(maybe_current, "filetype") == "netrw" then
          buf = maybe_current
        end
      end
      if buf then
        attach_obsidian_tree_behavior(buf, normalized)
      end
    end, 20)
  end

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

local function open_obsidian_note_in_vscode()
  open_obsidian_note_with({ "code", "code-insiders" }, "VS Code")
end

map("n", "<leader>ov", open_obsidian_tree, vim.tbl_extend("force", default_opts, { desc = "Open Obsidian file tree" }))
map("n", [[\of]], open_obsidian_note_in_firefox, vim.tbl_extend("force", default_opts, { desc = "Open Obsidian note in Firefox" }))
map("n", [[\ox]], open_obsidian_note_in_vscode, vim.tbl_extend("force", default_opts, { desc = "Open Obsidian note in VS Code" }))

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
