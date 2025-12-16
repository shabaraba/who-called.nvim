-- Column Width: ウィンドウの各カラム幅を計算

local M = {}

function M.get(win)
  local signcolumn = vim.wo[win].signcolumn
  local number = vim.wo[win].number
  local relativenumber = vim.wo[win].relativenumber
  local foldcolumn = vim.wo[win].foldcolumn

  local sign_width = 0
  if signcolumn == "yes" or signcolumn == "auto" then
    sign_width = 2
  elseif signcolumn:match("^yes:") or signcolumn:match("^auto:") then
    sign_width = tonumber(signcolumn:match(":(%d+)")) or 2
  end

  local number_width = 0
  if number or relativenumber then
    number_width = vim.wo[win].numberwidth or 4
  end

  local fold_width = 0
  if type(foldcolumn) == "string" then
    fold_width = tonumber(foldcolumn) or 0
  else
    fold_width = foldcolumn or 0
  end

  return {
    sign = sign_width,
    number = number_width,
    fold = fold_width,
    total_gutter = sign_width + number_width + fold_width,
  }
end

return M
