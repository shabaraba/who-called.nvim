-- Inspector Live Gather: 現在のウィンドウ/バッファ情報を収集

local M = {}

local sign = require("who-called.utils.sign")
local winbar = require("who-called.utils.winbar")
local lsp = require("who-called.utils.lsp")
local treesitter = require("who-called.utils.treesitter")
local plugin_guess = require("who-called.utils.plugin-guess")
local float_detect = require("who-called.ui.float-detect")
local state = require("who-called.inspector-live.state")

function M.get_current_info()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  if buf == state.get_live_buf() then
    return nil
  end

  local bufname = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype
  local buftype = vim.bo[buf].buftype
  local is_float = float_detect.is_floating(win)

  local plugin = plugin_guess.from_vars(win, buf)

  local live_win = state.get_live_win()
  local floats = float_detect.get_visible_floats(live_win)

  for i, float in ipairs(floats) do
    floats[i].plugin = plugin_guess.from_vars(float.win, float.buf)
  end

  return {
    win = win,
    buf = buf,
    bufname = bufname,
    filetype = ft,
    buftype = buftype,
    is_float = is_float,
    plugin = plugin,
    floats = floats,
  }
end

function M.get_rendering_info(win, buf)
  local info = {}

  info.winbar_plugin = winbar.get_plugin(win)
  info.sign_plugins = sign.get_all_plugins(buf)
  info.lsp_clients = lsp.get_clients(buf)

  local ts_info = treesitter.get_info(buf)
  if ts_info then
    info.treesitter = ts_info.lang
  end

  return info
end

return M
