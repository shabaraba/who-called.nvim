-- Hover State: モジュール状態管理

local M = {}

local state = {
  hover_win = nil,
  hover_buf = nil,
  hover_timer = nil,
  enabled = false,
  original_mouse = nil,
  original_mousemoveevent = nil,
}

function M.get(key)
  return state[key]
end

function M.set(key, value)
  state[key] = value
end

function M.is_enabled()
  return state.enabled
end

function M.get_hover_win()
  return state.hover_win
end

function M.get_hover_buf()
  return state.hover_buf
end

function M.reset()
  state.hover_win = nil
  state.hover_buf = nil
  state.hover_timer = nil
  state.enabled = false
  state.original_mouse = nil
  state.original_mousemoveevent = nil
end

return M
