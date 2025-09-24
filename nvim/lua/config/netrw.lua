local api = vim.api
local fn = vim.fn

local group = api.nvim_create_augroup("config_netrw", { clear = true })

api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "netrw",
  callback = function(event)
    local buf = event.buf

    if vim.b[buf].config_netrw_split_applied then
      return
    end

    if #fn.win_findbuf(buf) > 1 then
      return
    end

    local alt_buf = fn.bufnr("#")
    if alt_buf <= 0 or alt_buf == buf then
      return
    end

    vim.b[buf].config_netrw_split_applied = true

    local alt_win = fn.bufwinid(alt_buf)
    if alt_win ~= -1 and alt_win ~= 0 then
      api.nvim_set_current_win(alt_win)
    else
      vim.cmd(string.format("keepalt buffer %d", alt_buf))
    end

    vim.cmd(string.format("keepalt vert sbuffer %d", buf))
  end,
})
