local api = vim.api
local fn = vim.fn

local group = api.nvim_create_augroup("config_netrw", { clear = true })

local function float_config(width_ratio, height_ratio)
  local columns = vim.o.columns
  local lines = vim.o.lines

  local width = math.max(math.floor(columns * width_ratio), 20)
  local height = math.max(math.floor(lines * height_ratio), 10)
  local row = math.floor((lines - height) / 2)
  local col = math.floor((columns - width) / 2)

  return {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }
end

api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "netrw",
  callback = function(event)
    local buf = event.buf

    if vim.b[buf].config_netrw_popup_applied then
      return
    end

    if #fn.win_findbuf(buf) > 1 then
      return
    end

    local origin_win = api.nvim_get_current_win()
    local alt_buf = fn.bufnr("#")

    if alt_buf > 0 and alt_buf ~= buf and api.nvim_buf_is_valid(alt_buf) then
      pcall(api.nvim_win_set_buf, origin_win, alt_buf)
    else
      local scratch = api.nvim_create_buf(false, true)
      api.nvim_buf_set_option(scratch, "bufhidden", "wipe")
      api.nvim_win_set_buf(origin_win, scratch)
    end

    local target_win = api.nvim_get_current_win()
    local target_winnr = fn.win_id2win(target_win)

    if target_winnr > 0 then
      vim.b[buf].config_netrw_target_winnr = target_winnr
      vim.g.netrw_chgwin = target_winnr
    end

    local win = api.nvim_open_win(buf, true, float_config(0.8, 0.8))
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"

    vim.b[buf].config_netrw_popup_applied = true
    vim.b[buf].config_netrw_popup_win = win

    api.nvim_create_autocmd("BufLeave", {
      buffer = buf,
      once = true,
      callback = function()
        if vim.g.netrw_chgwin == target_winnr then
          vim.g.netrw_chgwin = nil
        end

        if api.nvim_win_is_valid(win) then
          pcall(api.nvim_win_close, win, true)
        end
      end,
    })
  end,
})
