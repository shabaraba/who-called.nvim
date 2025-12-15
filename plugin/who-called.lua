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
  require("who-called.inspector").inspect()
end, {})
