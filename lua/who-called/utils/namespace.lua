-- Namespace: namespace ID からプラグイン名を解決

local M = {}

local namespace_cache = nil

local function refresh_namespace_cache()
  namespace_cache = vim.api.nvim_get_namespaces()
end

function M.to_plugin(ns_id)
  if not ns_id then
    return nil
  end

  if not namespace_cache then
    refresh_namespace_cache()
  end

  for name, id in pairs(namespace_cache) do
    if id == ns_id then
      return name
    end
  end

  refresh_namespace_cache()
  for name, id in pairs(namespace_cache) do
    if id == ns_id then
      return name
    end
  end

  return nil
end

function M.get_all()
  if not namespace_cache then
    refresh_namespace_cache()
  end
  return namespace_cache
end

function M.invalidate_cache()
  namespace_cache = nil
end

return M
