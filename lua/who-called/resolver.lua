-- Resolver: ファイルパスからプラグイン名を解決

local M = {}

-- lazy.nvim のプラグインディレクトリ
local function get_lazy_path()
  return vim.fn.stdpath("data") .. "/lazy"
end

-- キャッシュ: プラグイン名とパスのマッピング
local plugin_cache = {}
local cache_initialized = false

-- キャッシュを初期化
local function init_cache()
  if cache_initialized then
    return
  end

  local lazy_path = get_lazy_path()
  if not vim.fn.isdirectory(lazy_path) == 1 then
    cache_initialized = true
    return
  end

  -- lazy.nvim から全プラグインを取得
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    cache_initialized = true
    return
  end

  local plugins = lazy.plugins()
  if type(plugins) == "table" then
    for _, plugin in ipairs(plugins) do
      if plugin.name then
        plugin_cache[plugin.name] = true
      end
    end
  end

  cache_initialized = true
end

-- ファイルパスからプラグイン名を抽出
function M.path_to_plugin(path)
  if not path or path == "" then
    return nil
  end

  init_cache()

  local lazy_path = get_lazy_path()

  -- パスが lazy ディレクトリの中にあるか確認
  if path:find(lazy_path, 1, true) then
    -- パスから プラグイン名を抽出: /lazy/plugin-name/...
    local plugin_name = path:match(lazy_path .. "/([^/]+)")
    if plugin_name and plugin_cache[plugin_name] then
      return plugin_name
    end
  end

  return nil
end

-- スタックトレース情報からプラグイン名を解決
function M.resolve(level)
  level = level or 2

  for i = level, 20 do
    local info = debug.getinfo(i)
    if not info then
      break
    end

    local source = info.source
    if source and source:sub(1, 1) == "@" then
      source = source:sub(2)  -- "@" を削除
      local plugin_name = M.path_to_plugin(source)
      if plugin_name then
        return plugin_name
      end
    end
  end

  return nil
end

-- スタックトレース全体を取得
function M.get_stack_trace(level)
  level = level or 2
  local stack = {}

  for i = level, 20 do
    local info = debug.getinfo(i)
    if not info then
      break
    end

    table.insert(stack, {
      file = info.source,
      line = info.currentline,
      name = info.name or "<anonymous>",
      func_line_start = info.linedefined,
      func_line_end = info.lastlinedefined,
    })
  end

  return stack
end

return M
