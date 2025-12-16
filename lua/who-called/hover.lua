-- Hover: マウスホバーでUI要素のプラグイン情報を表示

local M = {}

local hover_win = nil
local hover_buf = nil
local hover_timer = nil
local enabled = false
local original_mouse = nil
local original_mousemoveevent = nil

local HOVER_DELAY_MS = 300

-- namespace ID からプラグイン名を取得（汎用）
local function namespace_to_plugin(ns_id)
  local namespaces = vim.api.nvim_get_namespaces()
  for name, id in pairs(namespaces) do
    if id == ns_id then
      return name
    end
  end
  return nil
end

-- sign group をそのまま返す（汎用）
local function signgroup_to_plugin(group)
  if not group or group == "" then
    return nil
  end
  return group
end

-- ウィンドウの各カラム幅を計算
local function get_column_widths(win)
  local signcolumn = vim.wo[win].signcolumn
  local number = vim.wo[win].number
  local relativenumber = vim.wo[win].relativenumber
  local foldcolumn = vim.wo[win].foldcolumn

  local sign_width = 0
  if signcolumn == "yes" or signcolumn == "auto" then
    sign_width = 2
  elseif signcolumn:match("^yes:") or signcolumn:match("^auto:") then
    sign_width = tonumber(signcolumn:match(":(%d+)")) or 2
  end

  local number_width = 0
  if number or relativenumber then
    number_width = vim.wo[win].numberwidth or 4
  end

  local fold_width = 0
  if type(foldcolumn) == "string" then
    fold_width = tonumber(foldcolumn) or 0
  else
    fold_width = foldcolumn or 0
  end

  return {
    sign = sign_width,
    number = number_width,
    fold = fold_width,
    total_gutter = sign_width + number_width + fold_width,
  }
end

-- スクリーン座標からフローティングウィンドウを検出
local function find_float_at_position(screenrow, screencol)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      -- フローティングウィンドウの位置とサイズを取得
      local row = config.row or 0
      local col = config.col or 0
      local width = config.width or 0
      local height = config.height or 0

      -- tonumber でnumber型に変換（vim.NIL対策）
      if type(row) == "table" then row = row[false] or 0 end
      if type(col) == "table" then col = col[false] or 0 end
      row = tonumber(row) or 0
      col = tonumber(col) or 0

      -- border の分を考慮（大まかに +1）
      if config.border then
        row = row - 1
        col = col - 1
        width = width + 2
        height = height + 2
      end

      -- マウス位置がこのウィンドウ内か判定
      if screenrow >= row and screenrow < row + height and
         screencol >= col and screencol < col + width then
        return win
      end
    end
  end
  return nil
end

-- マウス位置からUI要素を判定
local function detect_ui_element(pos)
  local win = pos.winid
  if not win or win == 0 then
    return nil
  end

  -- フローティングウィンドウを優先的に検出
  local float_win = find_float_at_position(pos.screenrow, pos.screencol)
  if float_win and float_win ~= hover_win then
    win = float_win
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local win_config = vim.api.nvim_win_get_config(win)
  local is_float = win_config.relative ~= ""

  -- フローティングウィンドウの場合は専用の element を返す
  if is_float then
    return {
      element = "floating",
      win = win,
      buf = buf,
      line = pos.line,
      column = pos.column,
      config = win_config,
    }
  end

  local widths = get_column_widths(win)
  local wincol = pos.wincol
  local winrow = pos.winrow
  local line = pos.line
  local column = pos.column

  -- ウィンドウの高さを取得
  local win_height = vim.api.nvim_win_get_height(win)
  local has_winbar = vim.wo[win].winbar ~= ""

  -- Winbar 判定（最上部、winrow は 1 から始まる）
  if has_winbar and winrow == 1 then
    return {
      element = "winbar",
      win = win,
      buf = buf,
      line = line,
      column = column,
    }
  end

  -- Sign column 判定
  if wincol <= widths.sign then
    return {
      element = "sign_column",
      win = win,
      buf = buf,
      line = line,
      column = column,
    }
  end

  -- Number column 判定
  if wincol <= widths.sign + widths.number then
    return {
      element = "number_column",
      win = win,
      buf = buf,
      line = line,
      column = column,
    }
  end

  -- Fold column 判定
  if wincol <= widths.total_gutter then
    return {
      element = "fold_column",
      win = win,
      buf = buf,
      line = line,
      column = column,
    }
  end

  -- Buffer content
  return {
    element = "buffer",
    win = win,
    buf = buf,
    line = line,
    column = column,
  }
end

-- Sign column のプラグイン情報を取得（sign_getplaced + extmarks）
local function get_sign_info(buf, line)
  local plugins = {}

  -- 1. 従来の sign_getplaced
  local ok, result = pcall(vim.fn.sign_getplaced, buf, { lnum = line })
  if ok and result and result[1] and result[1].signs then
    for _, sign in ipairs(result[1].signs) do
      local plugin = signgroup_to_plugin(sign.group)
      if plugin and not vim.tbl_contains(plugins, plugin) then
        table.insert(plugins, plugin)
      end
    end
  end

  -- 2. extmarks ベースのサイン（gitsigns 等）
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf,
    -1,
    { line - 1, 0 },
    { line - 1, -1 },
    { details = true }
  )
  for _, mark in ipairs(extmarks) do
    local details = mark[4]
    if details and (details.sign_text or details.sign_hl_group) then
      local plugin = nil
      -- namespace_id から汎用的に解決
      if details.ns_id then
        plugin = namespace_to_plugin(details.ns_id)
      end
      -- namespace で見つからなければ hl_group から推測
      if not plugin and details.sign_hl_group then
        local hl = details.sign_hl_group
        -- CamelCase の先頭部分を抽出（例: GitSignsAdd → GitSigns）
        local prefix = hl:match("^(%u%l+%u?%l*)")
        if prefix then
          plugin = prefix .. " (from hl)"
        end
      end
      if plugin and not vim.tbl_contains(plugins, plugin) then
        table.insert(plugins, plugin)
      end
    end
  end

  if #plugins == 0 then
    return nil
  end
  return plugins
end

-- Extmarks のプラグイン情報を取得
local function get_extmark_info(buf, line, column)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf,
    -1, -- all namespaces
    { line - 1, 0 },
    { line - 1, -1 },
    { details = true }
  )

  local plugins = {}
  for _, mark in ipairs(extmarks) do
    local ns_id = mark[4] and mark[4].ns_id or nil
    if ns_id then
      local plugin = namespace_to_plugin(ns_id)
      if plugin and not vim.tbl_contains(plugins, plugin) then
        table.insert(plugins, plugin)
      end
    end
  end

  return plugins
end

-- Winbar のプラグイン情報を取得
local function get_winbar_info(win)
  local winbar = vim.wo[win].winbar
  if not winbar or winbar == "" then
    return nil
  end

  local plugins = {}

  -- 1. フックで追跡された情報をチェック
  local ok, tracked = pcall(vim.api.nvim_win_get_var, win, "who_called_winbar")
  if ok and tracked then
    table.insert(plugins, tracked .. " ✓")
    return plugins
  end

  -- 2. ハイライトグループから推測
  local option_hook = require("who-called.hooks.option")
  local from_highlight = option_hook.resolve_from_highlight_groups(winbar)
  if from_highlight then
    table.insert(plugins, from_highlight)
    return plugins
  end

  -- 3. フォールバック: よく使われるパターンマッチ
  if winbar:match("[Nn]avic") then
    table.insert(plugins, "nvim-navic")
  elseif winbar:match("[Bb]arbecue") then
    table.insert(plugins, "barbecue.nvim")
  elseif winbar:match("[Ss]aga") then
    table.insert(plugins, "lspsaga.nvim")
  elseif winbar:match("dropbar") then
    table.insert(plugins, "dropbar.nvim")
  elseif winbar:match("incline") then
    table.insert(plugins, "incline.nvim")
  end

  if #plugins == 0 then
    table.insert(plugins, "(unknown)")
  end

  return plugins
end

-- LSP 情報を取得
local function get_lsp_info(buf)
  local clients = vim.lsp.get_clients({ bufnr = buf })
  if #clients == 0 then
    return nil
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return names
end

-- Treesitter 情報を取得
local function get_treesitter_info(buf)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if ok and parser then
    return { "nvim-treesitter (" .. parser:lang() .. ")" }
  end
  return nil
end

-- 表示内容を生成
local function format_hover_info(ui_info)
  if not ui_info then
    return nil
  end

  local lines = {}
  local element = ui_info.element
  local buf = ui_info.buf
  local line = ui_info.line
  local win = ui_info.win

  table.insert(lines, "─── " .. element:upper():gsub("_", " ") .. " ───")

  if element == "sign_column" then
    local signs = get_sign_info(buf, line)
    if signs and #signs > 0 then
      for _, plugin in ipairs(signs) do
        table.insert(lines, " 📍 " .. plugin)
      end
    else
      table.insert(lines, " (no signs)")
    end
  elseif element == "number_column" then
    local has_number = vim.wo[win].number
    local has_rnu = vim.wo[win].relativenumber
    if has_number and has_rnu then
      table.insert(lines, " 🔢 hybrid number (native)")
    elseif has_number then
      table.insert(lines, " 🔢 number (native)")
    elseif has_rnu then
      table.insert(lines, " 🔢 relativenumber (native)")
    end
  elseif element == "fold_column" then
    local foldmethod = vim.wo[win].foldmethod
    table.insert(lines, " 📁 foldmethod: " .. foldmethod)
    if foldmethod == "expr" then
      local foldexpr = vim.wo[win].foldexpr
      if foldexpr:match("nvim_treesitter") then
        table.insert(lines, " → nvim-treesitter")
      elseif foldexpr:match("ufo") then
        table.insert(lines, " → nvim-ufo")
      end
    end
  elseif element == "winbar" then
    local plugins = get_winbar_info(win)
    if plugins then
      for _, plugin in ipairs(plugins) do
        table.insert(lines, " 🍞 " .. plugin)
      end
    end
  elseif element == "buffer" then
    -- Buffer 上の情報をまとめて表示
    local extmarks = get_extmark_info(buf, line, ui_info.column)
    if extmarks and #extmarks > 0 then
      table.insert(lines, " Extmarks:")
      for _, plugin in ipairs(extmarks) do
        table.insert(lines, "   ✦ " .. plugin)
      end
    end

    local lsp = get_lsp_info(buf)
    if lsp and #lsp > 0 then
      table.insert(lines, " LSP:")
      for _, name in ipairs(lsp) do
        table.insert(lines, "   💡 " .. name)
      end
    end

    local ts = get_treesitter_info(buf)
    if ts then
      table.insert(lines, " Syntax:")
      for _, info in ipairs(ts) do
        table.insert(lines, "   🌳 " .. info)
      end
    end

    local signs = get_sign_info(buf, line)
    if signs and #signs > 0 then
      table.insert(lines, " Signs (this line):")
      for _, plugin in ipairs(signs) do
        table.insert(lines, "   📍 " .. plugin)
      end
    end
  elseif element == "floating" then
    -- フローティングウィンドウのプラグイン情報
    local plugin = nil

    -- 1. ウィンドウ変数から追跡情報を取得
    local ok, tracked = pcall(vim.api.nvim_win_get_var, win, "who_called_plugin")
    if ok and tracked then
      plugin = tracked .. " ✓"
    end

    -- 2. バッファ変数から取得
    if not plugin then
      local ok2, buf_tracked = pcall(vim.api.nvim_buf_get_var, buf, "who_called_plugin")
      if ok2 and buf_tracked then
        plugin = buf_tracked .. " ✓"
      end
    end

    -- 3. filetype から推測
    if not plugin then
      local ft = vim.bo[buf].filetype
      if ft and ft ~= "" then
        plugin = ft .. " (filetype)"
      end
    end

    -- 4. タイトルを取得
    local config = ui_info.config
    local title_str = nil
    if config and config.title then
      local title = config.title
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

    if title_str then
      table.insert(lines, " 📝 " .. title_str)
    end
    if plugin then
      table.insert(lines, " 🪟 " .. plugin)
    else
      table.insert(lines, " 🪟 (unknown)")
    end
  end

  if #lines <= 1 then
    return nil
  end

  return lines
end

-- ホバーウィンドウを閉じる
local function close_hover()
  if hover_win and vim.api.nvim_win_is_valid(hover_win) then
    vim.api.nvim_win_close(hover_win, true)
  end
  hover_win = nil
  hover_buf = nil
end

-- ホバーウィンドウを表示
local function show_hover(pos, lines)
  close_hover()

  local ok_buf, buf = pcall(vim.api.nvim_create_buf, false, true)
  if not ok_buf then
    if vim.g.who_called_debug then
      print("show_hover: buf create failed:", buf)
    end
    return
  end
  hover_buf = buf

  vim.api.nvim_buf_set_lines(hover_buf, 0, -1, false, lines)
  vim.bo[hover_buf].bufhidden = "wipe"
  vim.bo[hover_buf].filetype = "who-called-hover"

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.max(width, 20)

  local row = pos.screenrow
  local col = pos.screencol + 2

  -- 画面右端を超えないように調整
  if col + width > vim.o.columns then
    col = vim.o.columns - width - 2
  end

  local ok_win, win = pcall(vim.api.nvim_open_win, hover_buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = #lines,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 250,
  })

  if not ok_win then
    if vim.g.who_called_debug then
      print("show_hover: win open failed:", win)
    end
    return
  end
  hover_win = win

  if vim.g.who_called_debug then
    print("show_hover: success, win=" .. hover_win)
  end

  pcall(vim.api.nvim_win_set_option, hover_win, "winblend", 10)

  -- cmdline モード等で再描画されない場合に強制再描画
  vim.cmd("redraw")
end

-- マウス移動ハンドラ
local function on_mouse_move()
  -- デバッグ: イベント発火確認
  if vim.g.who_called_debug then
    vim.schedule(function()
      print("MouseMove: mode=" .. vim.fn.mode())
    end)
  end

  if hover_timer then
    hover_timer:stop()
  end

  -- expr マッピング内ではウィンドウ操作できないので schedule
  vim.schedule(close_hover)

  hover_timer = vim.uv.new_timer()
  hover_timer:start(HOVER_DELAY_MS, 0, vim.schedule_wrap(function()
    local pos = vim.fn.getmousepos()

    -- デバッグ: getmousepos の結果
    if vim.g.who_called_debug then
      print("getmousepos: winid=" .. pos.winid .. " line=" .. pos.line)
    end

    if pos.winid == 0 then
      return
    end

    local ui_info = detect_ui_element(pos)
    local lines = format_hover_info(ui_info)

    -- デバッグ: hover 表示判定
    if vim.g.who_called_debug then
      print("ui_info:", ui_info and ui_info.element or "nil", "lines:", lines and #lines or "nil")
    end

    if lines then
      show_hover(pos, lines)
    end
  end))
end

-- ホバー機能を開始
function M.start()
  if enabled then
    vim.notify("Who-called hover already enabled", vim.log.levels.WARN)
    return
  end

  -- mouse を有効化（マウスイベント受信に必要）
  original_mouse = vim.o.mouse
  if vim.o.mouse == "" then
    vim.o.mouse = "a"
  end

  -- mousemoveevent を有効化
  original_mousemoveevent = vim.o.mousemoveevent
  vim.o.mousemoveevent = true

  -- MouseMove イベントをマッピング（cmdline モード含む）
  vim.keymap.set({ "n", "v", "i", "c" }, "<MouseMove>", function()
    on_mouse_move()
    return "<MouseMove>"
  end, { expr = true, silent = true, desc = "who-called hover" })

  enabled = true
  vim.notify("Who-called hover enabled", vim.log.levels.INFO)
end

-- ホバー機能を停止
function M.stop()
  if not enabled then
    return
  end

  -- タイマーをクリア
  if hover_timer then
    hover_timer:stop()
    hover_timer:close()
    hover_timer = nil
  end

  close_hover()

  -- キーマップを削除
  pcall(vim.keymap.del, { "n", "v", "i", "c" }, "<MouseMove>")

  -- mouse を元に戻す
  if original_mouse ~= nil then
    vim.o.mouse = original_mouse
  end

  -- mousemoveevent を元に戻す
  if original_mousemoveevent ~= nil then
    vim.o.mousemoveevent = original_mousemoveevent
  end

  enabled = false
  vim.notify("Who-called hover disabled", vim.log.levels.INFO)
end

-- トグル
function M.toggle()
  if enabled then
    M.stop()
  else
    M.start()
  end
end

-- 状態確認
function M.is_enabled()
  return enabled
end

return M
