local map = vim.keymap.set
local default_opts = { noremap = true, silent = true }

map({ "n", "v" }, "<Space>", "<Nop>", default_opts)

map("n", "<leader>w", "<cmd>w<cr>", vim.tbl_extend("force", default_opts, { desc = "Save file" }))
map("n", "<leader>q", "<cmd>qa<cr>", vim.tbl_extend("force", default_opts, { desc = "Quit Neovim" }))
map("n", "<leader>h", "<cmd>nohlsearch<cr>", vim.tbl_extend("force", default_opts, { desc = "Clear search highlight" }))
map("n", "<leader>bd", "<cmd>bdelete<cr>", vim.tbl_extend("force", default_opts, { desc = "Delete buffer" }))
map("n", "<leader>bn", "<cmd>bnext<cr>", vim.tbl_extend("force", default_opts, { desc = "Next buffer" }))
map("n", "<leader>bp", "<cmd>bprevious<cr>", vim.tbl_extend("force", default_opts, { desc = "Previous buffer" }))

map("n", "<leader>tn", "<cmd>tabnew<cr>", vim.tbl_extend("force", default_opts, { desc = "New tab" }))
map("n", "<leader>to", "<cmd>tabonly<cr>", vim.tbl_extend("force", default_opts, { desc = "Close other tabs" }))
map("n", "<leader>tc", "<cmd>tabclose<cr>", vim.tbl_extend("force", default_opts, { desc = "Close tab" }))
