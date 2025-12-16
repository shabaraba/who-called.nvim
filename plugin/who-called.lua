-- Commands for who-called.nvim

local who_called = require("who-called")

-- コマンド定義
vim.api.nvim_create_user_command("WhoCalled", function()
  who_called.enable()
  vim.notify("who-called enabled", vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("WhoCalledDisable", function()
  who_called.disable()
  vim.notify("who-called disabled", vim.log.levels.INFO)
end, {})

vim.api.nvim_create_user_command("WhoCalledHistory", function()
  who_called.show_history()
end, {})

vim.api.nvim_create_user_command("WhoCalledClear", function()
  who_called.clear_history()
end, {})

vim.api.nvim_create_user_command("WhoCalledStats", function()
  who_called.stats()
end, {})

vim.api.nvim_create_user_command("WhoCalledToggle", function()
  if who_called.is_enabled() then
    who_called.disable()
    vim.notify("who-called disabled", vim.log.levels.INFO)
  else
    who_called.enable()
    vim.notify("who-called enabled", vim.log.levels.INFO)
  end
end, {})

vim.api.nvim_create_user_command("WhoCalledInspect", function()
  -- コマンド実行時のウィンドウ/バッファを記録してから Inspector を開く
  local target_win = vim.api.nvim_get_current_win()
  local target_buf = vim.api.nvim_get_current_buf()
  require("who-called.inspector").inspect(target_win, target_buf)
end, {})

vim.api.nvim_create_user_command("WhoCalledLive", function()
  require("who-called.inspector-live").toggle()
end, {})

vim.api.nvim_create_user_command("WhoCalledLiveStart", function()
  require("who-called.inspector-live").start()
end, {})

vim.api.nvim_create_user_command("WhoCalledLiveStop", function()
  require("who-called.inspector-live").stop()
end, {})

vim.api.nvim_create_user_command("WhoCalledHover", function()
  require("who-called.hover").toggle()
end, {})

vim.api.nvim_create_user_command("WhoCalledHoverStart", function()
  require("who-called.hover").start()
end, {})

vim.api.nvim_create_user_command("WhoCalledHoverStop", function()
  require("who-called.hover").stop()
end, {})
