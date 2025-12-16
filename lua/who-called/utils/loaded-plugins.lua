-- Loaded Plugins: lazy.nvim からロード済みプラグインを取得

local M = {}

local cache = nil

function M.get_all()
  if cache then
    return cache
  end

  local loaded = {}
  local ok, lazy = pcall(require, "lazy")
  if ok then
    local plugins = lazy.plugins()
    for _, plugin in ipairs(plugins) do
      if plugin._.loaded then
        loaded[plugin.name] = true
      end
    end
  end

  cache = loaded
  return loaded
end

function M.is_loaded(name)
  local loaded = M.get_all()
  return loaded[name] == true
end

function M.invalidate_cache()
  cache = nil
end

return M
