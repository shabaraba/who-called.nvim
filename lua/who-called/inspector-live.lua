-- Inspector Live: カーソル追従型のリアルタイム Inspector

local M = {}

local live_win = nil
local live_buf = nil
local autocmd_group = nil

-- ウィンドウ/バッファからプラグインを推測（フック追跡のみ）
local function guess_plugin(win, buf)
  -- 1. ウィンドウ変数から (who-called tracking)
  local ok, win_plugin = pcall(vim.api.nvim_win_get_var, win, "who_called_plugin")
  if ok and win_plugin then
    return win_plugin .. " ✓"
  end

  -- 2. バッファ変数から
  local ok2, buf_plugin = pcall(vim.api.nvim_buf_get_var, buf, "who_called_plugin")
  if ok2 and buf_plugin then
    return buf_plugin .. " ✓"
  end

  return nil
end

-- 表示中のフローティングウィンドウを取得
local function get_visible_floats()
  local floats = {}
  local wins = vim.api.nvim_list_wins()

  for _, win in ipairs(wins) do
    -- Inspector 自身は除外
    if win ~= live_win then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then
        local buf = vim.api.nvim_win_get_buf(win)
        local plugin = guess_plugin(win, buf)
        local title = config.title

        -- タイトルを文字列に変換
        local title_str = nil
        if title then
          if type(title) == "string" then
            title_str = title
          elseif type(title) == "table" and #title > 0 then
            local first = title[1]
            if type(first) == "string" then
              title_str = first
            elseif type(first) == "table" and first[1] then
              title_str = first[1]
            end
          end
        end

        table.insert(floats, {
          win = win,
          buf = buf,
          plugin = plugin,
          title = title_str,
        })
      end
    end
  end

  return floats
end

-- 現在のウィンドウ/バッファ情報を取得
local function get_current_info()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  -- Inspector 自身は除外
  if buf == live_buf then
    return nil
  end

  local bufname = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype
  local buftype = vim.bo[buf].buftype
  local win_config = vim.api.nvim_win_get_config(win)
  local is_float = win_config.relative ~= ""

  local plugin = guess_plugin(win, buf)

  -- 表示中のフローティングウィンドウも取得
  local floats = get_visible_floats()

  return {
    win = win,
    buf = buf,
    bufname = bufname,
    filetype = ft,
    buftype = buftype,
    is_float = is_float,
    plugin = plugin,
    floats = floats,
  }
end

-- 表示内容を生成
local function format_info(info)
  if not info then
    return { " Inspector: (self) " }
  end

  local lines = {}
  local plugin_str = info.plugin or "?"
  local ft_str = info.filetype ~= "" and info.filetype or "-"
  local type_str = info.is_float and "float" or "normal"

  -- 現在のバッファ情報
  table.insert(lines, " ── Current ──")
  table.insert(lines, string.format(" 📦 %s", plugin_str))
  table.insert(lines, string.format(" ft: %s | %s", ft_str, type_str))

  -- バッファ名（短縮）
  if info.bufname and info.bufname ~= "" then
    local short_name = vim.fn.fnamemodify(info.bufname, ":t")
    if #short_name > 25 then
      short_name = short_name:sub(1, 22) .. "..."
    end
    table.insert(lines, string.format(" %s", short_name))
  end

  -- フローティングウィンドウ情報
  if info.floats and #info.floats > 0 then
    table.insert(lines, "")
    table.insert(lines, " ── Floats ──")
    for _, float in ipairs(info.floats) do
      local float_plugin = float.plugin or "?"
      local float_title = float.title and (" " .. float.title) or ""
      -- タイトルを短縮
      if #float_title > 20 then
        float_title = float_title:sub(1, 17) .. "..."
      end
      table.insert(lines, string.format(" 🪟 %s%s", float_plugin, float_title))
    end
  end

  return lines
end

-- 表示を更新
local function update_display()
  if not live_buf or not vim.api.nvim_buf_is_valid(live_buf) then
    return
  end
  if not live_win or not vim.api.nvim_win_is_valid(live_win) then
    return
  end

  local info = get_current_info()
  local lines = format_info(info)

  vim.bo[live_buf].modifiable = true
  vim.api.nvim_buf_set_lines(live_buf, 0, -1, false, lines)
  vim.bo[live_buf].modifiable = false

  -- ウィンドウサイズを内容に合わせる
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
  end

  local width = math.max(max_width, 20)
  local height = #lines

  vim.api.nvim_win_set_config(live_win, {
    relative = "editor",
    width = width,
    height = height,
    col = vim.o.columns - width - 1,
    row = vim.o.lines - height - 4,
  })
end

-- Live Inspector を開始
function M.start()
  if live_win and vim.api.nvim_win_is_valid(live_win) then
    vim.notify("Inspector Live already running", vim.log.levels.WARN)
    return
  end

  -- バッファ作成
  live_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[live_buf].bufhidden = "wipe"
  vim.bo[live_buf].filetype = "who-called-inspector"

  -- ウィンドウ作成（右下）
  local width = 25
  local height = 3

  live_win = vim.api.nvim_open_win(live_buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = vim.o.columns - width - 1,
    row = vim.o.lines - height - 4,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 50,
  })

  -- ハイライト設定
  vim.api.nvim_win_set_option(live_win, "winblend", 10)

  -- 自動更新の autocmd を設定
  autocmd_group = vim.api.nvim_create_augroup("WhoCalledInspectorLive", { clear = true })

  -- バッファ/ウィンドウ移動時
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "CursorMoved" }, {
    group = autocmd_group,
    callback = function()
      vim.schedule(update_display)
    end,
  })

  -- フローティングウィンドウの出現/消滅を検知
  vim.api.nvim_create_autocmd({ "WinNew", "WinClosed", "WinScrolled" }, {
    group = autocmd_group,
    callback = function()
      vim.schedule(update_display)
    end,
  })

  -- 定期的な更新（100ms）- フローティングウィンドウの検知用
  local timer = vim.loop.new_timer()
  timer:start(100, 200, vim.schedule_wrap(function()
    if live_win and vim.api.nvim_win_is_valid(live_win) then
      update_display()
    else
      timer:stop()
      timer:close()
    end
  end))

  -- 初回更新
  update_display()

  vim.notify("Inspector Live started", vim.log.levels.INFO)
end

-- Live Inspector を停止
function M.stop()
  if autocmd_group then
    vim.api.nvim_del_augroup_by_id(autocmd_group)
    autocmd_group = nil
  end

  if live_win and vim.api.nvim_win_is_valid(live_win) then
    vim.api.nvim_win_close(live_win, true)
  end

  live_win = nil
  live_buf = nil

  vim.notify("Inspector Live stopped", vim.log.levels.INFO)
end

-- トグル
function M.toggle()
  if live_win and vim.api.nvim_win_is_valid(live_win) then
    M.stop()
  else
    M.start()
  end
end

-- 状態確認
function M.is_running()
  return live_win ~= nil and vim.api.nvim_win_is_valid(live_win)
end

return M
