-- Float Window: フローティングウィンドウの作成・管理

local M = {}

function M.create(lines, opts)
  opts = opts or {}

  local ok_buf, buf = pcall(vim.api.nvim_create_buf, false, true)
  if not ok_buf then
    return nil, nil
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = opts.modifiable or false

  if opts.filetype then
    vim.bo[buf].filetype = opts.filetype
  end

  local width = opts.width
  if not width then
    width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    width = math.max(width, opts.min_width or 20)
  end

  local height = opts.height or #lines

  local row = opts.row or 0
  local col = opts.col or 0

  if opts.position == "bottom-right" then
    row = vim.o.lines - height - 4
    col = vim.o.columns - width - 1
  elseif opts.position == "center" then
    row = math.floor((vim.o.lines - height) / 2)
    col = math.floor((vim.o.columns - width) / 2)
  end

  local win_opts = {
    relative = opts.relative or "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = opts.style or "minimal",
    border = opts.border or "rounded",
    focusable = opts.focusable or false,
    zindex = opts.zindex or 50,
  }

  if opts.title then
    win_opts.title = opts.title
    win_opts.title_pos = opts.title_pos or "center"
  end

  local ok_win, win = pcall(vim.api.nvim_open_win, buf, opts.enter or false, win_opts)
  if not ok_win then
    return nil, buf
  end

  if opts.winblend then
    pcall(vim.api.nvim_win_set_option, win, "winblend", opts.winblend)
  end

  return win, buf
end

function M.close(win, buf)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

function M.update_content(buf, lines)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  return true
end

function M.resize_to_content(win, lines, opts)
  opts = opts or {}

  if not win or not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.max(width, opts.min_width or 20)

  local height = #lines
  local row = opts.row
  local col = opts.col

  if opts.position == "bottom-right" then
    row = vim.o.lines - height - 4
    col = vim.o.columns - width - 1
  end

  vim.api.nvim_win_set_config(win, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
  })

  return true
end

return M
