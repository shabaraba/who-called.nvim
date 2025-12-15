-- Hook: LSP diagnostic をフック

local M = {}
local config = require("who-called.config")
local resolver = require("who-called.resolver")
local history = require("who-called.history")

local original_set = nil
local original_open_float = nil
local hooked = false

-- フックを有効化
function M.enable()
  if hooked then
    return
  end

  original_set = vim.diagnostic.set

  vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
    if config.get("track_diagnostics") and diagnostics then
      for _, diag in ipairs(diagnostics) do
        local source = diag.source or "unknown"
        local original_message = diag.message

        history.add({
          type = "diagnostic",
          plugin = source,
          message = original_message,
          level = diag.severity,
          stack = {},
        })

        -- メッセージに [source] を付与
        if config.get("show_in_notify") then
          diag.message = string.format("[%s] %s", source, original_message)
        end
      end
    end

    return original_set(namespace, bufnr, diagnostics, opts)
  end

  -- vim.diagnostic.open_float をフック（診断 hover に [plugin-name] を表示）
  original_open_float = vim.diagnostic.open_float

  vim.diagnostic.open_float = function(bufnr, opts)
    opts = opts or {}

    if config.get("show_in_notify") then
      local plugin_name = resolver.resolve(2)
      if plugin_name then
        if opts.border and not opts.title then
          opts.title = string.format("[%s]", plugin_name)
        end
      end
    end

    return original_open_float(bufnr, opts)
  end

  hooked = true
end

-- フックを無効化
function M.disable()
  if not hooked or not original_set then
    return
  end

  vim.diagnostic.set = original_set
  if original_open_float then
    vim.diagnostic.open_float = original_open_float
  end
  hooked = false
end

-- フック状態を確認
function M.is_hooked()
  return hooked
end

return M
