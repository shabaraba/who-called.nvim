-- Hook: LSP diagnostic をフック

local M = {}
local config = require("who-called.config")
local history = require("who-called.history")

local original_get = nil
local hooked = false

-- フックを有効化
function M.enable()
  if hooked then
    return
  end

  original_get = vim.diagnostic.get

  vim.diagnostic.get = function(bufnr, opts)
    local diagnostics = original_get(bufnr, opts)

    if config.get("track_diagnostics") and diagnostics then
      for _, diag in ipairs(diagnostics) do
        local source = diag.source or "unknown"

        history.add({
          type = "diagnostic",
          plugin = source,
          message = diag.message,
          level = diag.severity,
          stack = {},
        })
      end
    end

    return diagnostics
  end

  hooked = true
end

-- フックを無効化
function M.disable()
  if not hooked or not original_get then
    return
  end

  vim.diagnostic.get = original_get
  hooked = false
end

-- フック状態を確認
function M.is_hooked()
  return hooked
end

return M
