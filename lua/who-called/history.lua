-- History: 追跡履歴の管理

local M = {}

local history = {}
local history_limit = 100

-- 履歴に エントリを追加
function M.add(entry)
  table.insert(history, {
    type = entry.type,
    plugin = entry.plugin or "unknown",
    message = entry.message or "",
    level = entry.level,
    timestamp = os.time(),
    stack = entry.stack,
  })

  -- 上限を超えた分を削除
  if #history > history_limit then
    table.remove(history, 1)
  end
end

-- 全履歴を取得
function M.get_all()
  return history
end

-- 特定タイプの履歴を取得
function M.get_by_type(type_name)
  local result = {}
  for _, entry in ipairs(history) do
    if entry.type == type_name then
      table.insert(result, entry)
    end
  end
  return result
end

-- 特定プラグインの履歴を取得
function M.get_by_plugin(plugin_name)
  local result = {}
  for _, entry in ipairs(history) do
    if entry.plugin == plugin_name then
      table.insert(result, entry)
    end
  end
  return result
end

-- 履歴をクリア
function M.clear()
  history = {}
end

-- 最後のエントリを取得
function M.get_last()
  if #history > 0 then
    return history[#history]
  end
  return nil
end

-- 履歴の件数
function M.count()
  return #history
end

-- 履歴の上限を設定
function M.set_limit(limit)
  history_limit = limit
end

-- 履歴を JSON 形式で取得（ほぼデバッグ用）
function M.to_json()
  return vim.json.encode(history)
end

return M
