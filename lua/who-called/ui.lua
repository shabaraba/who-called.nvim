-- UI: 履歴表示

local M = {}
local history = require("who-called.history")

-- タイムスタンプを見やすい形式に変換
local function format_time(timestamp)
  return os.date("%H:%M:%S", timestamp)
end

-- 履歴をバッファに表示
function M.show_history()
  -- 新しいバッファを作成
  local buf = vim.api.nvim_create_buf(false, true)

  local entries = history.get_all()
  local lines = {}

  -- ヘッダー
  table.insert(lines, "=== Who Called? History ===")
  table.insert(lines, "")

  if #entries == 0 then
    table.insert(lines, "No entries recorded yet.")
  else
    for i, entry in ipairs(entries) do
      local type_icon = {
        notify = "🔔",
        window = "🪟",
        diagnostic = "❌",
      }[entry.type] or "?"

      table.insert(
        lines,
        string.format(
          "%d. [%s] %s: %s",
          i,
          entry.type,
          entry.plugin,
          entry.message
        )
      )
      table.insert(lines, string.format("   Time: %s", format_time(entry.timestamp)))
      table.insert(lines, "")
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- ウィンドウを作成
  local width = 80
  local height = math.min(#lines + 2, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- キーマッピング: q で閉じる
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, noremap = true })
end

return M
