local util = require("config.util")

return {
  name = "nvim-tree.lua",
  dir = util.vendor("nvim-tree.lua"),
  dependencies = {
    "nvim-web-devicons",
  },
  init = function()
    local group = vim.api.nvim_create_augroup("nvim_tree_auto_open", { clear = true })

    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      callback = function(data)
        local path = data.file or ""
        if path == "" or vim.fn.isdirectory(path) ~= 1 then
          return
        end

        vim.cmd.cd(path)
        require("lazy").load({ plugins = { "nvim-tree.lua" } })
        require("nvim-tree.api").tree.open()
      end,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      callback = function(data)
        local path = data.file or ""
        if path == "" or vim.fn.isdirectory(path) ~= 1 then
          return
        end

        require("lazy").load({ plugins = { "nvim-tree.lua" } })
        require("nvim-tree.api").tree.open()
        pcall(vim.api.nvim_buf_delete, data.buf, { force = true })
      end,
    })
  end,
  cmd = {
    "NvimTreeToggle",
    "NvimTreeFocus",
    "NvimTreeFindFile",
  },
  keys = {
    {
      "<leader>e",
      function()
        require("nvim-tree.api").tree.toggle({ focus = false })
      end,
      desc = "Toggle file explorer",
    },
  },
  config = function()
    require("nvim-tree").setup({
      disable_netrw = false,
      hijack_netrw = false,
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      view = {
        width = 35,
      },
    })
  end,
}
