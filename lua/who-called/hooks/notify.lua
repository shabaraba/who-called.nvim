-- Hook: vim.notify をフック

local M = {}
local config = require("who-called.config")
local resolver = require("who-called.resolver")
local history = require("who-called.history")

local original_notify = nil
local hooked = false

-- フックを有効化
function M.enable()
  if hooked then
    return
  end

  -- 元の vim.notify を保存
  original_notify = vim.notify

  vim.notify = function(msg, level, opts)
    if config.get("track_notify") then
      local plugin_name = resolver.resolve(2)

      -- メッセージに [plugin-name] を付与
      if plugin_name and config.get("show_in_notify") then
        msg = string.format("[%s] %s", plugin_name, tostring(msg))
      end

      -- 履歴に記録
      history.add({
        type = "notify",
        plugin = plugin_name,
        message = msg,
        level = level,
        stack = resolver.get_stack_trace(2),
      })
    end

    -- 元の notify を呼び出し
    original_notify(msg, level, opts)
  end

  hooked = true
end

-- フックを無効化
function M.disable()
  if not hooked or not original_notify then
    return
  end

  vim.notify = original_notify
  hooked = false
end

-- フック状態を確認
function M.is_hooked()
  return hooked
end

return M
