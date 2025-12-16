-- Inspector: 現在のウィンドウ/バッファの詳細情報を表示

local M = {}

local display = require("who-called.inspector.display")

function M.inspect(target_win, target_buf)
  local win = target_win or vim.api.nvim_get_current_win()
  local buf = target_buf or vim.api.nvim_get_current_buf()

  local info = display.create_display(win, buf)
  display.show_in_float(info)
end

return M
