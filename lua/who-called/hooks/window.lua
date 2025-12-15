-- Hook: nvim_open_win をフック

local M = {}
local config = require("who-called.config")
local resolver = require("who-called.resolver")
local history = require("who-called.history")

local original_open_win = nil
local hooked = false

-- フックを有効化
function M.enable()
  if hooked then
    return
  end

  original_open_win = vim.api.nvim_open_win

  vim.api.nvim_open_win = function(buffer, enter, config_opts)
    local win_id = original_open_win(buffer, enter, config_opts)

    if config.get("track_windows") then
      local plugin_name = resolver.resolve(2)

      -- ウィンドウにメタデータを付与
      if plugin_name then
        pcall(vim.api.nvim_win_set_var, win_id, "who_called_plugin", plugin_name)
      end

      -- 履歴に記録
      history.add({
        type = "window",
        plugin = plugin_name,
        message = string.format("Floating window created (buffer=%d)", buffer),
        stack = resolver.get_stack_trace(2),
      })
    end

    return win_id
  end

  hooked = true
end

-- フックを無効化
function M.disable()
  if not hooked or not original_open_win then
    return
  end

  vim.api.nvim_open_win = original_open_win
  hooked = false
end

-- フック状態を確認
function M.is_hooked()
  return hooked
end

return M
