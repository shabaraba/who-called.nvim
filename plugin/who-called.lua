-- Commands for who-called.nvim

local who_called = require("who-called")

-- メインコマンド: トラッキング + Live Inspector + Hover を一括トグル
vim.api.nvim_create_user_command("WhoCalled", function()
  local live = require("who-called.inspector-live")
  local hover = require("who-called.hover")

  if who_called.is_enabled() then
    who_called.disable()
    live.stop()
    hover.stop()
    vim.notify("who-called disabled", vim.log.levels.INFO)
  else
    who_called.enable()
    live.start()
    hover.start()
    vim.notify("who-called enabled", vim.log.levels.INFO)
  end
end, {})

-- 静的検査: 現在のウィンドウ/バッファを1回だけ検査
vim.api.nvim_create_user_command("WhoCalledInspect", function()
  local target_win = vim.api.nvim_get_current_win()
  local target_buf = vim.api.nvim_get_current_buf()
  require("who-called.inspector").inspect(target_win, target_buf)
end, {})

-- 履歴表示
vim.api.nvim_create_user_command("WhoCalledHistory", function()
  who_called.show_history()
end, {})

-- 履歴クリア
vim.api.nvim_create_user_command("WhoCalledClear", function()
  who_called.clear_history()
end, {})
