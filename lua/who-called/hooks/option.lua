-- Hook: オプション設定（winbar, statusline 等）をフック

local M = {}
local resolver = require("who-called.resolver")
local history = require("who-called.history")

local autocmd_group = nil
local hooked = false

-- 追跡するオプション
local tracked_options = {
  "winbar",
  "statusline",
  "tabline",
}

-- ハイライトグループ名からプラグインを推測
local function resolve_from_highlight_groups(value)
  if not value or value == "" then
    return nil
  end

  -- %#GroupName# パターンを抽出
  local groups = {}
  for group in value:gmatch("%%#([^#]+)#") do
    table.insert(groups, group)
  end

  if #groups == 0 then
    return nil
  end

  -- ハイライトグループ名からプラグイン名を推測
  -- 一般的なパターン: プラグイン名がプレフィックスになっている
  local candidates = {}

  for _, group in ipairs(groups) do
    -- よくあるパターンをチェック
    local lower = group:lower()

    -- package.loaded から一致するモジュールを探す
    for module_name, _ in pairs(package.loaded) do
      if type(module_name) == "string" then
        local module_lower = module_name:lower()
        -- ハイライトグループ名の一部がモジュール名に含まれているか
        local prefix = lower:match("^(%a+)")
        if prefix and #prefix >= 3 then
          if module_lower:match(prefix) then
            -- モジュール名からプラグイン名を抽出
            local plugin = module_name:match("^([^%.]+)")
            if plugin and not vim.tbl_contains(candidates, plugin) then
              table.insert(candidates, plugin)
            end
          end
        end
      end
    end
  end

  -- 候補が多すぎる場合は最初のハイライトグループから推測
  if #candidates == 0 and #groups > 0 then
    local first_group = groups[1]
    -- CamelCase から推測（例: SagaFolder → saga）
    local prefix = first_group:match("^(%u%l+)")
    if prefix then
      return prefix:lower() .. " (from highlight)"
    end
  end

  if #candidates > 0 then
    return candidates[1]
  end

  return nil
end

-- オプション変更時のハンドラ
local function on_option_set(opt, scope)
  local plugin_name = resolver.resolve(3) -- autocmd callback から 3 レベル上

  -- スタックトレースで見つからない場合、ハイライトグループから推測
  if not plugin_name then
    local value = nil
    if scope == "global" then
      value = vim.o[opt]
    else
      value = vim.wo[opt] or vim.bo[opt]
    end
    plugin_name = resolve_from_highlight_groups(value)
  end

  -- ウィンドウ/バッファ変数に保存
  local var_name = "who_called_" .. opt
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  if plugin_name then
    if opt == "winbar" or opt == "statusline" then
      pcall(vim.api.nvim_win_set_var, win, var_name, plugin_name)
    elseif opt == "tabline" then
      vim.g[var_name] = plugin_name
    end
  end

  -- 履歴に記録
  history.add({
    type = "option",
    plugin = plugin_name,
    message = string.format("Option '%s' set (scope=%s)", opt, scope),
    stack = resolver.get_stack_trace(3),
  })
end

-- フックを有効化
function M.enable()
  if hooked then
    return
  end

  autocmd_group = vim.api.nvim_create_augroup("WhoCalledOptionHook", { clear = true })

  -- OptionSet イベントで監視
  vim.api.nvim_create_autocmd("OptionSet", {
    group = autocmd_group,
    pattern = tracked_options,
    callback = function(args)
      local opt = args.match
      local scope = vim.v.option_type -- "global" or "local"
      vim.schedule(function()
        on_option_set(opt, scope)
      end)
    end,
  })

  hooked = true
end

-- フックを無効化
function M.disable()
  if not hooked then
    return
  end

  if autocmd_group then
    vim.api.nvim_del_augroup_by_id(autocmd_group)
    autocmd_group = nil
  end

  hooked = false
end

-- フック状態を確認
function M.is_hooked()
  return hooked
end

-- 外部から利用可能: ハイライトグループからプラグインを推測
M.resolve_from_highlight_groups = resolve_from_highlight_groups

return M
