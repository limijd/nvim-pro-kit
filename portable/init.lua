-- Portable Neovim Configuration (All-in-One)
-- Zero plugin dependencies, works anywhere

--------------------------------------------------------------------------------
-- Terminal Detection
--------------------------------------------------------------------------------
local function has_truecolor()
  local term = vim.env.TERM or ""
  local colorterm = vim.env.COLORTERM or ""
  if colorterm:match("truecolor") or colorterm:match("24bit") then
    return true
  end
  if term:match("256color") or term:match("kitty") or term:match("alacritty") then
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- Basic Options
--------------------------------------------------------------------------------
local opt = vim.opt

opt.number = true
opt.relativenumber = false
opt.cursorline = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true
opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.ignorecase = true
opt.smartcase = true
opt.timeoutlen = 400
opt.updatetime = 250
opt.completeopt = { "menu", "menuone", "noselect" }
opt.wrap = false
opt.mouse = ""
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.hlsearch = true
opt.incsearch = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.showmode = false  -- statusline shows mode

-- Persistent undo (if writable)
local state_dir = vim.fn.stdpath("state")
if state_dir and vim.fn.isdirectory(state_dir) == 1 then
  local undo_dir = state_dir .. "/undo"
  if vim.fn.isdirectory(undo_dir) == 0 then
    vim.fn.mkdir(undo_dir, "p")
  end
  if vim.fn.filewritable(undo_dir) == 2 then
    opt.undofile = true
    opt.undodir = undo_dir
  end
end

-- Enable termguicolors if supported
if has_truecolor() then
  opt.termguicolors = true
end

--------------------------------------------------------------------------------
-- Onedark Colorscheme (Embedded)
--------------------------------------------------------------------------------
local function setup_onedark()
  local colors = {
    bg = "#282c34",
    fg = "#abb2bf",
    black = "#1e222a",
    red = "#e06c75",
    green = "#98c379",
    yellow = "#e5c07b",
    blue = "#61afef",
    purple = "#c678dd",
    cyan = "#56b6c2",
    white = "#abb2bf",
    gray = "#5c6370",
    bright_black = "#3e4451",
    bright_red = "#e06c75",
    bright_green = "#98c379",
    bright_yellow = "#d19a66",
    bright_blue = "#61afef",
    bright_purple = "#c678dd",
    bright_cyan = "#56b6c2",
    bright_white = "#ffffff",
    comment = "#5c6370",
    gutter = "#4b5263",
    selection = "#3e4451",
    cursorline = "#2c323c",
    statusline = "#21252b",
  }

  vim.cmd("highlight clear")
  vim.g.colors_name = "onedark_portable"

  local hl = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Editor
  hl("Normal", { fg = colors.fg, bg = colors.bg })
  hl("NormalFloat", { fg = colors.fg, bg = colors.black })
  hl("FloatBorder", { fg = colors.gray, bg = colors.black })
  hl("Cursor", { fg = colors.bg, bg = colors.fg })
  hl("CursorLine", { bg = colors.cursorline })
  hl("CursorColumn", { bg = colors.cursorline })
  hl("LineNr", { fg = colors.gutter })
  hl("CursorLineNr", { fg = colors.yellow })
  hl("SignColumn", { bg = colors.bg })
  hl("VertSplit", { fg = colors.bright_black })
  hl("WinSeparator", { fg = colors.bright_black })
  hl("ColorColumn", { bg = colors.cursorline })
  hl("Visual", { bg = colors.selection })
  hl("VisualNOS", { bg = colors.selection })
  hl("Search", { fg = colors.black, bg = colors.yellow })
  hl("IncSearch", { fg = colors.black, bg = colors.bright_yellow })
  hl("Pmenu", { fg = colors.fg, bg = colors.black })
  hl("PmenuSel", { fg = colors.black, bg = colors.blue })
  hl("PmenuSbar", { bg = colors.bright_black })
  hl("PmenuThumb", { bg = colors.gray })
  hl("StatusLine", { fg = colors.fg, bg = colors.statusline })
  hl("StatusLineNC", { fg = colors.gray, bg = colors.statusline })
  hl("TabLine", { fg = colors.gray, bg = colors.statusline })
  hl("TabLineFill", { bg = colors.statusline })
  hl("TabLineSel", { fg = colors.fg, bg = colors.bg })
  hl("Folded", { fg = colors.gray, bg = colors.cursorline })
  hl("FoldColumn", { fg = colors.gray })
  hl("MatchParen", { fg = colors.yellow, bold = true })
  hl("NonText", { fg = colors.bright_black })
  hl("SpecialKey", { fg = colors.bright_black })
  hl("Directory", { fg = colors.blue })
  hl("Title", { fg = colors.green, bold = true })
  hl("ErrorMsg", { fg = colors.red })
  hl("WarningMsg", { fg = colors.yellow })
  hl("MoreMsg", { fg = colors.green })
  hl("ModeMsg", { fg = colors.fg, bold = true })
  hl("Question", { fg = colors.green })

  -- Syntax
  hl("Comment", { fg = colors.comment, italic = true })
  hl("Constant", { fg = colors.cyan })
  hl("String", { fg = colors.green })
  hl("Character", { fg = colors.green })
  hl("Number", { fg = colors.bright_yellow })
  hl("Boolean", { fg = colors.bright_yellow })
  hl("Float", { fg = colors.bright_yellow })
  hl("Identifier", { fg = colors.red })
  hl("Function", { fg = colors.blue })
  hl("Statement", { fg = colors.purple })
  hl("Conditional", { fg = colors.purple })
  hl("Repeat", { fg = colors.purple })
  hl("Label", { fg = colors.purple })
  hl("Operator", { fg = colors.cyan })
  hl("Keyword", { fg = colors.purple })
  hl("Exception", { fg = colors.purple })
  hl("PreProc", { fg = colors.yellow })
  hl("Include", { fg = colors.purple })
  hl("Define", { fg = colors.purple })
  hl("Macro", { fg = colors.purple })
  hl("PreCondit", { fg = colors.yellow })
  hl("Type", { fg = colors.yellow })
  hl("StorageClass", { fg = colors.yellow })
  hl("Structure", { fg = colors.yellow })
  hl("Typedef", { fg = colors.yellow })
  hl("Special", { fg = colors.blue })
  hl("SpecialChar", { fg = colors.bright_yellow })
  hl("Tag", { fg = colors.red })
  hl("Delimiter", { fg = colors.fg })
  hl("SpecialComment", { fg = colors.gray })
  hl("Debug", { fg = colors.red })
  hl("Underlined", { underline = true })
  hl("Error", { fg = colors.red })
  hl("Todo", { fg = colors.purple, bold = true })

  -- Diff
  hl("DiffAdd", { bg = "#2a3429" })
  hl("DiffChange", { bg = "#1d3548" })
  hl("DiffDelete", { fg = colors.red, bg = "#3c2828" })
  hl("DiffText", { bg = "#2b5b77" })

  -- Diagnostics
  hl("DiagnosticError", { fg = colors.red })
  hl("DiagnosticWarn", { fg = colors.yellow })
  hl("DiagnosticInfo", { fg = colors.blue })
  hl("DiagnosticHint", { fg = colors.cyan })

  -- Statusline highlight groups
  hl("StatusModeNormal", { fg = colors.black, bg = colors.green, bold = true })
  hl("StatusModeInsert", { fg = colors.black, bg = colors.blue, bold = true })
  hl("StatusModeVisual", { fg = colors.black, bg = colors.purple, bold = true })
  hl("StatusModeReplace", { fg = colors.black, bg = colors.red, bold = true })
  hl("StatusModeCommand", { fg = colors.black, bg = colors.yellow, bold = true })
  hl("StatusModeTerminal", { fg = colors.black, bg = colors.cyan, bold = true })
end

local function setup_fallback_colorscheme()
  -- Use built-in colorscheme for 256-color terminals
  pcall(vim.cmd, "colorscheme habamax")
end

if vim.opt.termguicolors:get() then
  setup_onedark()
else
  setup_fallback_colorscheme()
end

--------------------------------------------------------------------------------
-- Statusline
--------------------------------------------------------------------------------
local mode_map = {
  n = { "NORMAL", "StatusModeNormal" },
  i = { "INSERT", "StatusModeInsert" },
  v = { "VISUAL", "StatusModeVisual" },
  V = { "V-LINE", "StatusModeVisual" },
  ["\22"] = { "V-BLOCK", "StatusModeVisual" },
  c = { "COMMAND", "StatusModeCommand" },
  R = { "REPLACE", "StatusModeReplace" },
  t = { "TERMINAL", "StatusModeTerminal" },
  s = { "SELECT", "StatusModeVisual" },
  S = { "S-LINE", "StatusModeVisual" },
  ["\19"] = { "S-BLOCK", "StatusModeVisual" },
}

function _G.portable_statusline()
  local mode = vim.fn.mode()
  local mode_info = mode_map[mode] or { mode:upper(), "StatusModeNormal" }
  local mode_str = mode_info[1]
  local mode_hl = mode_info[2]

  local filename = vim.fn.expand("%:t")
  if filename == "" then
    filename = "[No Name]"
  end
  local modified = vim.bo.modified and " [+]" or ""
  local readonly = vim.bo.readonly and " [RO]" or ""

  local filetype = vim.bo.filetype ~= "" and vim.bo.filetype or "none"
  local encoding = vim.opt.fileencoding:get()
  if encoding == "" then encoding = "utf-8" end

  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local total = vim.fn.line("$")
  local percent = math.floor(line / total * 100)

  return string.format(
    " %%#%s# %s %%#StatusLine# │ %s%s%s │ %s │ %s │ %d:%d │ %d%%%% ",
    mode_hl, mode_str,
    filename, modified, readonly,
    filetype, encoding,
    line, col, percent
  )
end

opt.statusline = "%{%v:lua.portable_statusline()%}"

--------------------------------------------------------------------------------
-- Comment Toggle
--------------------------------------------------------------------------------
local comment_strings = {
  lua = "--",
  python = "#",
  ruby = "#",
  bash = "#",
  sh = "#",
  zsh = "#",
  yaml = "#",
  toml = "#",
  make = "#",
  dockerfile = "#",
  conf = "#",
  c = "//",
  cpp = "//",
  java = "//",
  javascript = "//",
  typescript = "//",
  go = "//",
  rust = "//",
  kotlin = "//",
  scala = "//",
  swift = "//",
  php = "//",
  css = "/*",
  sql = "--",
  haskell = "--",
  vim = '"',
  tex = "%",
  matlab = "%",
  lisp = ";",
  clojure = ";",
  scheme = ";",
  asm = ";",
  html = "<!--",
  xml = "<!--",
}

local function get_comment_string()
  local ft = vim.bo.filetype
  if comment_strings[ft] then
    return comment_strings[ft]
  end
  -- Fallback: try to use commentstring option
  local cs = vim.bo.commentstring
  if cs and cs ~= "" then
    local prefix = cs:match("^(.-)%%s")
    if prefix then
      return vim.trim(prefix)
    end
  end
  return "#"
end

local function toggle_comment_line(lnum)
  local line = vim.fn.getline(lnum)
  local cs = get_comment_string()
  local cs_escaped = vim.pesc(cs)

  -- Check if line is commented
  local indent, rest = line:match("^(%s*)(.*)")
  if rest:match("^" .. cs_escaped .. "%s?") then
    -- Uncomment
    local uncommented = rest:gsub("^" .. cs_escaped .. "%s?", "", 1)
    vim.fn.setline(lnum, indent .. uncommented)
  else
    -- Comment
    if rest ~= "" then
      vim.fn.setline(lnum, indent .. cs .. " " .. rest)
    end
  end
end

local function toggle_comment_range(line1, line2)
  for lnum = line1, line2 do
    toggle_comment_line(lnum)
  end
end

-- gcc - toggle current line
vim.keymap.set("n", "gcc", function()
  toggle_comment_line(vim.fn.line("."))
end, { noremap = true, silent = true, desc = "Toggle comment" })

-- gc{motion}
vim.keymap.set("n", "gc", function()
  vim.opt.operatorfunc = "v:lua.portable_comment_operator"
  return "g@"
end, { noremap = true, expr = true, desc = "Comment operator" })

function _G.portable_comment_operator(type)
  local line1 = vim.fn.line("'[")
  local line2 = vim.fn.line("']")
  toggle_comment_range(line1, line2)
end

-- Visual mode gc
vim.keymap.set("x", "gc", function()
  local line1 = vim.fn.line("'<")
  local line2 = vim.fn.line("'>")
  toggle_comment_range(line1, line2)
  vim.cmd("normal! gv")
end, { noremap = true, silent = true, desc = "Toggle comment" })

--------------------------------------------------------------------------------
-- Auto Pairs
--------------------------------------------------------------------------------
local pairs_map = {
  ["("] = ")",
  ["["] = "]",
  ["{"] = "}",
  ['"'] = '"',
  ["'"] = "'",
  ["`"] = "`",
}

local function autopair_insert(open, close)
  return function()
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local next_char = line:sub(col, col)

    -- For quotes, don't pair if inside a word
    if open == close then
      local prev_char = line:sub(col - 1, col - 1)
      if prev_char:match("%w") or next_char:match("%w") then
        return open
      end
      -- If next char is the same quote, just move past it
      if next_char == close then
        return "<Right>"
      end
    end

    return open .. close .. "<Left>"
  end
end

local function autopair_close(close)
  return function()
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local next_char = line:sub(col, col)

    if next_char == close then
      return "<Right>"
    end
    return close
  end
end

local function autopair_backspace()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  local prev_char = line:sub(col - 1, col - 1)
  local next_char = line:sub(col, col)

  if pairs_map[prev_char] and pairs_map[prev_char] == next_char then
    return "<BS><Del>"
  end
  return "<BS>"
end

-- Set up pair mappings
for open, close in pairs(pairs_map) do
  if open == close then
    vim.keymap.set("i", open, autopair_insert(open, close), { expr = true, noremap = true })
  else
    vim.keymap.set("i", open, autopair_insert(open, close), { expr = true, noremap = true })
    vim.keymap.set("i", close, autopair_close(close), { expr = true, noremap = true })
  end
end

vim.keymap.set("i", "<BS>", autopair_backspace, { expr = true, noremap = true })

--------------------------------------------------------------------------------
-- Enhanced Text Objects
--------------------------------------------------------------------------------
-- ii/ai - indent text object
local function select_indent(around)
  local start_line = vim.fn.line(".")
  local start_indent = vim.fn.indent(start_line)

  -- Find start of block
  local block_start = start_line
  while block_start > 1 do
    local prev_indent = vim.fn.indent(block_start - 1)
    local prev_line = vim.fn.getline(block_start - 1)
    if prev_line:match("^%s*$") then
      -- Empty line
      if not around then break end
    elseif prev_indent < start_indent then
      break
    end
    block_start = block_start - 1
  end

  -- Find end of block
  local total = vim.fn.line("$")
  local block_end = start_line
  while block_end < total do
    local next_indent = vim.fn.indent(block_end + 1)
    local next_line = vim.fn.getline(block_end + 1)
    if next_line:match("^%s*$") then
      if not around then break end
    elseif next_indent < start_indent then
      break
    end
    block_end = block_end + 1
  end

  -- Select
  vim.cmd("normal! " .. block_start .. "GV" .. block_end .. "G")
end

vim.keymap.set("x", "ii", function() select_indent(false) end, { noremap = true, silent = true, desc = "Inner indent" })
vim.keymap.set("x", "ai", function() select_indent(true) end, { noremap = true, silent = true, desc = "Around indent" })
vim.keymap.set("o", "ii", function() select_indent(false) end, { noremap = true, silent = true, desc = "Inner indent" })
vim.keymap.set("o", "ai", function() select_indent(true) end, { noremap = true, silent = true, desc = "Around indent" })

-- ie/ae - entire file text object
vim.keymap.set("x", "ie", ":<C-u>normal! ggVG<CR>", { noremap = true, silent = true, desc = "Inner entire" })
vim.keymap.set("x", "ae", ":<C-u>normal! ggVG<CR>", { noremap = true, silent = true, desc = "Around entire" })
vim.keymap.set("o", "ie", ":<C-u>normal! ggVG<CR>", { noremap = true, silent = true, desc = "Inner entire" })
vim.keymap.set("o", "ae", ":<C-u>normal! ggVG<CR>", { noremap = true, silent = true, desc = "Around entire" })

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Disable space in normal/visual mode
map({ "n", "v" }, "<Space>", "<Nop>", opts)

-- Basic operations
map("n", "<leader>w", "<cmd>w<cr>", vim.tbl_extend("force", opts, { desc = "Save file" }))
map("n", "<leader>q", "<cmd>qa<cr>", vim.tbl_extend("force", opts, { desc = "Quit" }))
map("n", "<leader>h", "<cmd>nohlsearch<cr>", vim.tbl_extend("force", opts, { desc = "Clear search highlight" }))

-- Buffer navigation
map("n", "<leader>bn", "<cmd>bnext<cr>", vim.tbl_extend("force", opts, { desc = "Next buffer" }))
map("n", "<leader>bp", "<cmd>bprevious<cr>", vim.tbl_extend("force", opts, { desc = "Previous buffer" }))
map("n", "<leader>bd", "<cmd>bdelete<cr>", vim.tbl_extend("force", opts, { desc = "Delete buffer" }))
map("n", "<leader>bl", "<cmd>ls<cr>", vim.tbl_extend("force", opts, { desc = "List buffers" }))

-- Tab navigation
map("n", "<leader>tn", "<cmd>tabnew<cr>", vim.tbl_extend("force", opts, { desc = "New tab" }))
map("n", "<leader>tc", "<cmd>tabclose<cr>", vim.tbl_extend("force", opts, { desc = "Close tab" }))
map("n", "<leader>to", "<cmd>tabonly<cr>", vim.tbl_extend("force", opts, { desc = "Close other tabs" }))
map("n", "[t", "<cmd>tabprevious<cr>", vim.tbl_extend("force", opts, { desc = "Previous tab" }))
map("n", "]t", "<cmd>tabnext<cr>", vim.tbl_extend("force", opts, { desc = "Next tab" }))

-- Window navigation
map("n", "<C-h>", "<C-w>h", vim.tbl_extend("force", opts, { desc = "Go to left window" }))
map("n", "<C-j>", "<C-w>j", vim.tbl_extend("force", opts, { desc = "Go to lower window" }))
map("n", "<C-k>", "<C-w>k", vim.tbl_extend("force", opts, { desc = "Go to upper window" }))
map("n", "<C-l>", "<C-w>l", vim.tbl_extend("force", opts, { desc = "Go to right window" }))

-- Window resize
map("n", "<C-Up>", "<cmd>resize +2<cr>", vim.tbl_extend("force", opts, { desc = "Increase window height" }))
map("n", "<C-Down>", "<cmd>resize -2<cr>", vim.tbl_extend("force", opts, { desc = "Decrease window height" }))
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", vim.tbl_extend("force", opts, { desc = "Decrease window width" }))
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", vim.tbl_extend("force", opts, { desc = "Increase window width" }))

-- Move lines
map("n", "<A-j>", "<cmd>move .+1<cr>==", vim.tbl_extend("force", opts, { desc = "Move line down" }))
map("n", "<A-k>", "<cmd>move .-2<cr>==", vim.tbl_extend("force", opts, { desc = "Move line up" }))
map("v", "<A-j>", ":move '>+1<cr>gv=gv", vim.tbl_extend("force", opts, { desc = "Move selection down" }))
map("v", "<A-k>", ":move '<-2<cr>gv=gv", vim.tbl_extend("force", opts, { desc = "Move selection up" }))

-- Better indenting
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Quick file explorer (netrw)
map("n", "<leader>e", "<cmd>Explore<cr>", vim.tbl_extend("force", opts, { desc = "File explorer" }))

-- Quick search and replace
map("n", "<leader>sr", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", { noremap = true, desc = "Search and replace word" })

-- Keep cursor centered
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)

-- Paste without losing register
map("x", "<leader>p", '"_dP', vim.tbl_extend("force", opts, { desc = "Paste without yank" }))

-- Yank to system clipboard
map({ "n", "v" }, "<leader>y", '"+y', vim.tbl_extend("force", opts, { desc = "Yank to clipboard" }))

-- Delete without yank
map({ "n", "v" }, "<leader>d", '"_d', vim.tbl_extend("force", opts, { desc = "Delete without yank" }))

--------------------------------------------------------------------------------
-- Useful Autocommands
--------------------------------------------------------------------------------
local augroup = vim.api.nvim_create_augroup("PortableNvim", { clear = true })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Return to last edit position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto-resize splits on window resize
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Remove trailing whitespace on save (optional, uncomment if needed)
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   group = augroup,
--   pattern = "*",
--   callback = function()
--     local save = vim.fn.winsaveview()
--     vim.cmd([[%s/\s\+$//e]])
--     vim.fn.winrestview(save)
--   end,
-- })

--------------------------------------------------------------------------------
-- File Type Settings
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "lua", "javascript", "typescript", "json", "yaml", "html", "css" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "man" },
  callback = function()
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, silent = true })
  end,
})

--------------------------------------------------------------------------------
-- Startup Message
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup,
  once = true,
  callback = function()
    if vim.fn.argc() == 0 then
      vim.schedule(function()
        print("Portable Neovim | \\w save | \\q quit | \\e explorer | \\h clear search")
      end)
    end
  end,
})
