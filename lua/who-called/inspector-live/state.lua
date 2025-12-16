-- Inspector Live State: モジュール状態管理

local M = {}

local state = {
  live_win = nil,
  live_buf = nil,
  autocmd_group = nil,
  timer = nil,
}

function M.get(key)
  return state[key]
end

function M.set(key, value)
  state[key] = value
end

function M.get_live_win()
  return state.live_win
end

function M.get_live_buf()
  return state.live_buf
end

function M.is_valid()
  return state.live_win ~= nil and vim.api.nvim_win_is_valid(state.live_win)
end

function M.reset()
  state.live_win = nil
  state.live_buf = nil
  state.autocmd_group = nil
  state.timer = nil
end

return M
