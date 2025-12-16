-- who-called.nvim: Main entry point

local M = {}

local config = require("who-called.config")
local history = require("who-called.history")
local notify_hook = require("who-called.hooks.notify")
local window_hook = require("who-called.hooks.window")
local diagnostic_hook = require("who-called.hooks.diagnostic")
local buffer_hook = require("who-called.hooks.buffer")
local option_hook = require("who-called.hooks.option")
local ui = require("who-called.ui")

local enabled = false

-- プラグインを初期化
function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  history.set_limit(config.get("history_limit"))

  -- vim.g.who_called_enabled をデフォルト値に設定
  if vim.g.who_called_enabled == nil then
    vim.g.who_called_enabled = config.get("enabled")
  end

  -- 初期状態で有効な場合は起動
  if vim.g.who_called_enabled then
    M.enable()
  end

  -- hover 自動起動
  if config.get("hover") then
    require("who-called.hover").start()
  end

  -- live_inspector 自動起動
  if config.get("live_inspector") then
    require("who-called.inspector-live").start()
  end
end

-- フックを有効化
function M.enable()
  if enabled then
    return
  end

  notify_hook.enable()
  window_hook.enable()
  diagnostic_hook.enable()
  buffer_hook.enable()
  option_hook.enable()

  enabled = true
  vim.g.who_called_enabled = true
end

-- フックを無効化
function M.disable()
  if not enabled then
    return
  end

  notify_hook.disable()
  window_hook.disable()
  diagnostic_hook.disable()
  buffer_hook.disable()
  option_hook.disable()

  enabled = false
  vim.g.who_called_enabled = false
end

-- 有効化状態を確認
function M.is_enabled()
  return enabled
end

-- 履歴を表示
function M.show_history()
  ui.show_history()
end

-- 履歴をクリア
function M.clear_history()
  history.clear()
  vim.notify("who-called history cleared", vim.log.levels.INFO)
end

return M
