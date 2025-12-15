-- Hook: バッファ作成をフック

local M = {}
local config = require("who-called.config")
local resolver = require("who-called.resolver")
local history = require("who-called.history")

local original_create_buf = nil
local hooked = false

function M.enable()
  if hooked then
    return
  end

  original_create_buf = vim.api.nvim_create_buf

  vim.api.nvim_create_buf = function(listed, scratch)
    local plugin_name = resolver.resolve(2)

    local bufnr = original_create_buf(listed, scratch)

    if config.get("track_buffers") and bufnr and bufnr > 0 then
      -- バッファにメタデータを付与
      if plugin_name then
        pcall(vim.api.nvim_buf_set_var, bufnr, "who_called_plugin", plugin_name)
      end

      -- 履歴に記録
      history.add({
        type = "buffer",
        plugin = plugin_name,
        message = string.format("Buffer created (bufnr=%d, listed=%s, scratch=%s)",
          bufnr, tostring(listed), tostring(scratch)),
        stack = resolver.get_stack_trace(2),
      })
    end

    return bufnr
  end

  hooked = true
end

function M.disable()
  if not hooked or not original_create_buf then
    return
  end

  vim.api.nvim_create_buf = original_create_buf
  hooked = false
end

function M.is_hooked()
  return hooked
end

return M
