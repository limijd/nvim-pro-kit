local map = vim.keymap.set
local default_opts = { noremap = true, silent = true }

map({ "n", "v" }, "<Space>", "<Nop>", default_opts)

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
