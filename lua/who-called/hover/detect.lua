-- Hover Detect: マウス位置からUI要素を検出

local M = {}

local column_width = require("who-called.ui.column-width")
local float_detect = require("who-called.ui.float-detect")
local state = require("who-called.hover.state")

function M.detect_ui_element(pos)
  local win = pos.winid
  if not win or win == 0 then
    return nil
  end

  local hover_win = state.get_hover_win()
  local float_info = float_detect.find_at_position(pos.screenrow, pos.screencol, hover_win)
  if float_info and float_info.win ~= hover_win then
    win = float_info.win
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local win_config = vim.api.nvim_win_get_config(win)
  local is_float = win_config.relative ~= ""

  if is_float then
    return {
      element = "floating",
      win = win,
      buf = buf,
      line = pos.line,
      column = pos.column,
      config = win_config,
    }
  end

  local widths = column_width.get(win)
  local wincol = pos.wincol
  local winrow = pos.winrow
  local line = pos.line
  local column = pos.column

  local has_winbar = vim.wo[win].winbar ~= ""

  if has_winbar and winrow == 1 then
    return {
      element = "winbar",
      win = win,
      buf = buf,
      line = line,
      column = column,
    }
  end

  if wincol <= widths.sign then
    return {
      element = "sign_column",
      win = win,
      buf = buf,
      line = line,
      column = column,
    }
  end

  if wincol <= widths.sign + widths.number then
    return {
      element = "number_column",
      win = win,
      buf = buf,
      line = line,
      column = column,
    }
  end

  if wincol <= widths.total_gutter then
    return {
      element = "fold_column",
      win = win,
      buf = buf,
      line = line,
      column = column,
    }
  end

  return {
    element = "buffer",
    win = win,
    buf = buf,
    line = line,
    column = column,
  }
end

return M
