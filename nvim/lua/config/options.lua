local opt = vim.opt

opt.termguicolors = true
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
opt.clipboard = "unnamedplus"

do
  local function in_tmux()
    local tmux_env = vim.env.TMUX
    return type(tmux_env) == "string" and tmux_env ~= ""
  end

  local function tmux_binary_available()
    return vim.fn.executable("tmux") == 1
  end

  -- Older tmux releases (for example the version bundled with CentOS 7) do not
  -- passthrough OSC 52 sequences. When Neovim detects an unavailable clipboard
  -- provider it falls back to OSC 52, which results in the escape sequence
  -- becoming visible in the editor instead of copying the text. Detect this
  -- scenario and prefer the tmux load-buffer / save-buffer workflow instead of
  -- relying on OSC 52.
  if vim.g.clipboard == nil and in_tmux() and tmux_binary_available() then
    local copy = "tmux load-buffer -w -"
    local paste = "tmux save-buffer -"

    vim.g.clipboard = {
      name = "tmux",
      copy = {
        ["+"] = copy,
        ["*"] = copy,
      },
      paste = {
        ["+"] = paste,
        ["*"] = paste,
      },
      cache_enabled = false,
    }
  end
end
opt.wrap = false
opt.mouse = "a"
