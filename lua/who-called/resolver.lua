-- Resolver: ファイルパスからプラグイン名を解決

local M = {}

-- lazy.nvim のプラグインディレクトリ
local function get_lazy_path()
  return vim.fn.stdpath("data") .. "/lazy"
end

-- ユーティリティプラグイン（UI部品を提供するプラグイン）は除外して、
-- 実際に機能を提供しているプラグインを表示する
local utility_plugins = {
  ["plenary.nvim"] = true,
  ["nui.nvim"] = true,
  ["nvim-notify"] = true,
  ["dressing.nvim"] = true,
  ["popup.nvim"] = true,
}

-- キャッシュ: プラグイン名とパスのマッピング
local plugin_cache = {}
local cache_initialized = false

-- filetype からプラグイン名へのマッピング（スタックトレースが取れない場合のフォールバック）
local filetype_to_plugin = {
  ["pile"] = "pile.nvim",
  ["oil"] = "oil.nvim",
  ["TelescopePrompt"] = "telescope.nvim",
  ["TelescopeResults"] = "telescope.nvim",
  ["neo-tree"] = "neo-tree.nvim",
  ["NvimTree"] = "nvim-tree.lua",
  ["lazy"] = "lazy.nvim",
  ["mason"] = "mason.nvim",
  ["lspinfo"] = "nvim-lspconfig",
  ["toggleterm"] = "toggleterm.nvim",
  ["trouble"] = "trouble.nvim",
  ["Outline"] = "outline.nvim",
  ["aerial"] = "aerial.nvim",
  ["DressingInput"] = "dressing.nvim",
  ["DressingSelect"] = "dressing.nvim",
  ["noice"] = "noice.nvim",
  ["notify"] = "nvim-notify",
  ["Navbuddy"] = "nvim-navbuddy",
  ["lspsagaoutline"] = "lspsaga.nvim",
  ["saga"] = "lspsaga.nvim",
}

-- キャッシュを初期化
local function init_cache()
  if cache_initialized then
    return
  end

  local lazy_path = get_lazy_path()
  if vim.fn.isdirectory(lazy_path) ~= 1 then
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

-- パターン用にエスケープ
local function escape_pattern(str)
  return str:gsub("([%.%-%+%[%]%(%)%$%^%%%?%*])", "%%%1")
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
    local escaped_path = escape_pattern(lazy_path)
    local plugin_name = path:match(escaped_path .. "/([^/]+)")
    if plugin_name and plugin_cache[plugin_name] then
      return plugin_name
    end
  end

  return nil
end

-- バッファの filetype からプラグイン名を推測
function M.resolve_from_buffer(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local ft = vim.bo[bufnr].filetype
  if ft and filetype_to_plugin[ft] then
    return filetype_to_plugin[ft]
  end

  -- バッファ名からも推測を試みる
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname then
    -- oil:// スキームをチェック
    if bufname:match("^oil://") then
      return "oil.nvim"
    end
    -- その他のスキーム
    if bufname:match("^neo%-tree://") then
      return "neo-tree.nvim"
    end
    if bufname:match("^NvimTree_") then
      return "nvim-tree.lua"
    end
  end

  return nil
end

-- スタックトレース情報からプラグイン名を解決
-- ユーティリティプラグインをスキップして、実際のプラグインを返す
function M.resolve(level)
  level = level or 2
  local fallback_plugin = nil

  for i = level, 30 do
    local info = debug.getinfo(i)
    if not info then
      break
    end

    local source = info.source
    if source and source:sub(1, 1) == "@" then
      source = source:sub(2)  -- "@" を削除
      local plugin_name = M.path_to_plugin(source)
      if plugin_name then
        -- ユーティリティプラグインはスキップ
        if not utility_plugins[plugin_name] then
          return plugin_name
        end
        -- フォールバック用に最初のプラグインを記録
        if not fallback_plugin then
          fallback_plugin = plugin_name
        end
      end
    end
  end

  -- 非ユーティリティプラグインが見つからなければユーティリティを返す
  return fallback_plugin
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
