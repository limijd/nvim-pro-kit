local util = require("config.util")
local tools = require("config.tools")

return {
  name = "git-worktree.nvim",
  dir = util.vendor("git-worktree.nvim"),
  dependencies = {
    "plenary.nvim",
    "telescope.nvim",
  },
  init = function()
    tools.git()
  end,
  config = function()
    local worktree = require("git-worktree")

    worktree.setup({})

    local telescope = require("telescope")
    pcall(telescope.load_extension, "git_worktree")

    local extension = telescope.extensions and telescope.extensions.git_worktree
    local function ensure_extension()
      if extension then
        return true
      end

      local ok = pcall(telescope.load_extension, "git_worktree")
      if ok then
        extension = telescope.extensions.git_worktree
      else
        vim.notify("git-worktree telescope extension unavailable", vim.log.levels.ERROR)
      end

      return extension ~= nil
    end

    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    map(
      "n",
      "<leader>gwt",
      function()
        if ensure_extension() then
          extension.git_worktrees()
        end
      end,
      vim.tbl_extend("force", opts, { desc = "Switch Git worktree" })
    )

    map(
      "n",
      "<leader>gwc",
      function()
        if ensure_extension() then
          extension.create_git_worktree()
        end
      end,
      vim.tbl_extend("force", opts, { desc = "Create Git worktree" })
    )
  end,
}
