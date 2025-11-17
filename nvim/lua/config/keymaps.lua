local map = vim.keymap.set
local default_opts = { noremap = true, silent = true }
local obsidian_tree_group = vim.api.nvim_create_augroup("NvimProKitObsidianTree", { clear = true })
local obsidian_hide_pattern = [[^\..*]]

map({ "n", "v" }, "<Space>", "<Nop>", default_opts)

local function apply_obsidian_tree_preferences(bufnr)
  local vars = vim.b[bufnr]
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
  if not vars.npk_obsidian_active then
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

local function attach_obsidian_tree_behavior(bufnr)
  ensure_obsidian_tree_autocmds(bufnr)
  apply_obsidian_tree_preferences(bufnr)
end

local function find_obsidian_tree_buffer(target_dir)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_option(buf, "filetype") == "netrw" then
      local curdir = vim.b[buf].netrw_curdir
      if curdir then
        local normalized_dir = vim.fs.normalize(curdir)
        if normalized_dir == target_dir then
          return buf
        end
      end
    end
  end
end

local function open_obsidian_tree()
  local vault_root = vim.env.NVIM_PRO_KIT_OBSIDIAN or vim.env.OBSIDIAN_VAULT or "~/Obsidian"
  local expanded = vim.fn.expand(vault_root)
  local normalized = expanded ~= "" and vim.fs.normalize(expanded) or nil

  if not normalized or normalized == "" then
    vim.notify("Obsidian vault path is empty", vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  local stat = vim.loop.fs_stat(normalized)
  if not stat or stat.type ~= "directory" then
    vim.notify(string.format("Obsidian vault not found: %s", normalized), vim.log.levels.WARN, { title = "keymaps" })
    return
  end

  local previous_winsize = vim.g.netrw_winsize
  vim.g.netrw_winsize = 33

  vim.cmd.lcd({ args = { normalized } })
  vim.cmd.Lexplore({ args = { normalized } })

  local tree_buf = find_obsidian_tree_buffer(normalized)
  if tree_buf then
    attach_obsidian_tree_behavior(tree_buf)
  end

  vim.schedule(function()
    if previous_winsize == nil then
      vim.g.netrw_winsize = nil
    else
      vim.g.netrw_winsize = previous_winsize
    end
  end)
end

map("n", "<leader>ov", open_obsidian_tree, vim.tbl_extend("force", default_opts, { desc = "Open Obsidian file tree" }))

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
