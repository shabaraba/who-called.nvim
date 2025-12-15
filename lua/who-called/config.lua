-- Config: 設定管理

local M = {}

local defaults = {
  enabled = false,
  history_limit = 100,
  show_in_notify = true,
  track_notify = true,
  track_windows = true,
  track_diagnostics = true,
  track_buffers = true,
}

local config = vim.tbl_extend("force", {}, defaults)

-- 設定をマージ
function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_extend("force", config, opts)
end

-- 設定を取得
function M.get(key)
  if key then
    return config[key]
  end
  return config
end

-- 設定を設定
function M.set(key, value)
  config[key] = value
end

-- デフォルト設定に戻す
function M.reset()
  config = vim.tbl_extend("force", {}, defaults)
end

return M
