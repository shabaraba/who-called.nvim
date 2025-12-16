-- Hover: マウスホバーでUI要素のプラグイン情報を表示

local M = {}

local state = require("who-called.hover.state")
local mouse = require("who-called.hover.mouse")

function M.start()
  if state.is_enabled() then
    vim.notify("Who-called hover already enabled", vim.log.levels.WARN)
    return
  end

  state.set("original_mouse", vim.o.mouse)
  if vim.o.mouse == "" then
    vim.o.mouse = "a"
  end

  state.set("original_mousemoveevent", vim.o.mousemoveevent)
  vim.o.mousemoveevent = true

  mouse.setup_keymaps()

  state.set("enabled", true)
  vim.notify("Who-called hover enabled", vim.log.levels.INFO)
end

function M.stop()
  if not state.is_enabled() then
    return
  end

  mouse.cleanup()
  mouse.remove_keymaps()

  local original_mouse = state.get("original_mouse")
  if original_mouse ~= nil then
    vim.o.mouse = original_mouse
  end

  local original_mousemoveevent = state.get("original_mousemoveevent")
  if original_mousemoveevent ~= nil then
    vim.o.mousemoveevent = original_mousemoveevent
  end

  state.set("enabled", false)
  vim.notify("Who-called hover disabled", vim.log.levels.INFO)
end

function M.toggle()
  if state.is_enabled() then
    M.stop()
  else
    M.start()
  end
end

function M.is_enabled()
  return state.is_enabled()
end

return M
