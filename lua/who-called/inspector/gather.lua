-- Inspector Gather: ウィンドウ/バッファ情報を収集

local M = {}

local sign = require("who-called.utils.sign")
local winbar = require("who-called.utils.winbar")

function M.get_buffer_info(buf)
  local bufname = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype
  local buftype = vim.bo[buf].buftype

  return {
    number = buf,
    name = bufname ~= "" and bufname or "(empty)",
    filetype = ft ~= "" and ft or "(none)",
    buftype = buftype ~= "" and buftype or "(normal)",
  }
end

function M.get_window_info(win)
  local win_config = vim.api.nvim_win_get_config(win)
  local is_float = win_config.relative ~= ""

  local info = {
    number = win,
    is_float = is_float,
    config = win_config,
  }

  if is_float then
    info.relative = win_config.relative
    if win_config.title then
      info.title = type(win_config.title) == "string"
        and win_config.title
        or vim.inspect(win_config.title)
    end
    if win_config.border then
      info.border = type(win_config.border) == "string"
        and win_config.border
        or "custom"
    end
  end

  local ok, win_plugin = pcall(vim.api.nvim_win_get_var, win, "who_called_plugin")
  if ok and win_plugin then
    info.tracked_plugin_win = win_plugin
  end

  return info
end

function M.get_sign_info(buf)
  return sign.get_all_plugins(buf)
end

function M.get_winbar_plugin(win)
  return winbar.get_plugin(win)
end

function M.get_statusline_plugin(win)
  local statusline = vim.o.statusline
  if not statusline or statusline == "" then
    return "native"
  end

  -- 1. フックで追跡された情報を確認
  local ok, tracked = pcall(vim.api.nvim_win_get_var, win, "who_called_statusline")
  if ok and tracked then
    return tracked .. " (tracked)"
  end

  -- 2. ハイライトグループ名から汎用的に推測
  local ok2, option_hook = pcall(require, "who-called.hooks.option")
  if ok2 and option_hook.resolve_from_highlight_groups then
    local from_hl = option_hook.resolve_from_highlight_groups(statusline)
    if from_hl then
      return from_hl
    end
  end

  return nil
end

function M.get_tabline_plugin()
  local tabline = vim.o.tabline
  if not tabline or tabline == "" then
    return nil
  end

  -- 1. フックで追跡された情報を確認（グローバル変数）
  local tracked = vim.g.who_called_tabline
  if tracked then
    return tracked .. " (tracked)"
  end

  -- 2. ハイライトグループ名から汎用的に推測
  local ok, option_hook = pcall(require, "who-called.hooks.option")
  if ok and option_hook.resolve_from_highlight_groups then
    local from_hl = option_hook.resolve_from_highlight_groups(tabline)
    if from_hl then
      return from_hl
    end
  end

  return nil
end

return M
