-- Hook: nvim_open_win をフック

local M = {}
local config = require("who-called.config")
local resolver = require("who-called.resolver")
local history = require("who-called.history")

local original_open_win = nil
local original_win_set_config = nil
local hooked = false

-- 同じプラグインからの連続ウィンドウ作成を抑制
local last_plugin = nil
local last_time = 0
local DEBOUNCE_MS = 100  -- 100ms以内の同じプラグインはスキップ

-- フックを有効化
function M.enable()
  if hooked then
    return
  end

  original_open_win = vim.api.nvim_open_win

  vim.api.nvim_open_win = function(buffer, enter, config_opts)
    local plugin_name = nil

    if config.get("track_windows") then
      plugin_name = resolver.resolve(2)

      -- スタックトレースで見つからない場合、バッファ情報からフォールバック
      if not plugin_name and buffer then
        plugin_name = resolver.resolve_from_buffer(buffer)
      end

      -- タイトルに [plugin-name] を追加または作成
      -- 同じプラグインからの連続ウィンドウ作成は最初だけタイトルを表示
      local now = vim.loop.now()
      local should_add_title = true
      if plugin_name == last_plugin and (now - last_time) < DEBOUNCE_MS then
        should_add_title = false
      else
        last_plugin = plugin_name
        last_time = now
      end

      local show_in_notify = config.get("show_in_notify")

      if plugin_name and show_in_notify and config_opts and should_add_title then
        local plugin_label = string.format("[%s] ", plugin_name)

        if config_opts.title then
          -- 既存の title に [plugin-name] を追加（重複チェック付き）
          local title = config_opts.title
          local pattern = "^%[" .. plugin_name .. "%]"

          if type(title) == "string" then
            if not title:match(pattern) then
              config_opts.title = plugin_label .. title
            end
          elseif type(title) == "table" and #title > 0 then
            local first_item = title[1]
            if type(first_item) == "string" then
              if not first_item:match(pattern) then
                title[1] = plugin_label .. first_item
              end
            elseif type(first_item) == "table" and first_item[1] then
              if not first_item[1]:match(pattern) then
                first_item[1] = plugin_label .. first_item[1]
              end
            end
          end
        else
          -- title がない場合、[plugin-name] を title として設定
          config_opts.title = string.format("[%s]", plugin_name)

          -- border がない or "none" の場合は rounded を設定して title を表示させる
          if not config_opts.border or config_opts.border == "none" then
            config_opts.border = "rounded"
          end
        end
      end
    end

    local win_id = original_open_win(buffer, enter, config_opts)

    if config.get("track_windows") then
      -- ウィンドウにメタデータを付与
      if plugin_name then
        pcall(vim.api.nvim_win_set_var, win_id, "who_called_plugin", plugin_name)
      end

      -- 履歴に記録
      history.add({
        type = "window",
        plugin = plugin_name,
        message = string.format("Floating window created (buffer=%d)", buffer),
        stack = resolver.get_stack_trace(2),
      })
    end

    return win_id
  end

  -- nvim_win_set_config もフック（後からタイトルを設定するプラグイン対応）
  original_win_set_config = vim.api.nvim_win_set_config

  vim.api.nvim_win_set_config = function(win, cfg)
    if config.get("track_windows") and config.get("show_in_notify") and cfg then
      -- ウィンドウに保存されたプラグイン名を取得
      local ok, plugin_name = pcall(vim.api.nvim_win_get_var, win, "who_called_plugin")
      if ok and plugin_name then
        -- タイトルが設定されようとしている場合、[plugin] を付与
        if cfg.title then
          local plugin_label = string.format("[%s] ", plugin_name)
          local title = cfg.title

          if type(title) == "string" then
            -- 既に [plugin] がついていなければ追加
            if not title:match("^%[" .. plugin_name .. "%]") then
              cfg.title = plugin_label .. title
            end
          elseif type(title) == "table" and #title > 0 then
            local first_item = title[1]
            if type(first_item) == "string" then
              if not first_item:match("^%[" .. plugin_name .. "%]") then
                title[1] = plugin_label .. first_item
              end
            elseif type(first_item) == "table" and first_item[1] then
              if not first_item[1]:match("^%[" .. plugin_name .. "%]") then
                first_item[1] = plugin_label .. first_item[1]
              end
            end
          end
        end
      end
    end

    return original_win_set_config(win, cfg)
  end

  hooked = true
end

-- フックを無効化
function M.disable()
  if not hooked or not original_open_win then
    return
  end

  vim.api.nvim_open_win = original_open_win
  if original_win_set_config then
    vim.api.nvim_win_set_config = original_win_set_config
  end
  hooked = false
end

-- フック状態を確認
function M.is_hooked()
  return hooked
end

return M
