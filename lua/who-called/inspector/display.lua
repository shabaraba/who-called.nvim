-- Inspector Display: 検査結果の表示生成

local M = {}

local gather = require("who-called.inspector.gather")
local float_window = require("who-called.ui.float-window")

function M.create_display(win, buf)
  local info = {
    "+-----------------------------------------+",
    "|        who-called.nvim Inspector        |",
    "+-----------------------------------------+",
    "",
  }

  local buf_info = gather.get_buffer_info(buf)
  table.insert(info, "Buffer Information:")
  table.insert(info, string.format("   Number: %d", buf_info.number))
  table.insert(info, string.format("   Name: %s", buf_info.name))
  table.insert(info, string.format("   Filetype: %s", buf_info.filetype))
  table.insert(info, string.format("   Buftype: %s", buf_info.buftype))

  local ok2, buf_plugin = pcall(vim.api.nvim_buf_get_var, buf, "who_called_plugin")
  if ok2 and buf_plugin then
    table.insert(info, string.format("   -> Plugin (buf tracked): %s", buf_plugin))
  end

  table.insert(info, "")

  local win_info = gather.get_window_info(win)
  table.insert(info, "Window Information:")
  table.insert(info, string.format("   Number: %d", win_info.number))
  table.insert(info, string.format("   Type: %s", win_info.is_float and "floating" or "normal"))

  if win_info.is_float then
    table.insert(info, string.format("   Relative: %s", win_info.relative))
    if win_info.title then
      table.insert(info, string.format("   Title: %s", win_info.title))
    end
    if win_info.border then
      table.insert(info, string.format("   Border: %s", win_info.border))
    end
  end

  if win_info.tracked_plugin_win then
    table.insert(info, string.format("   -> Plugin (win tracked): %s", win_info.tracked_plugin_win))
  end

  table.insert(info, "")

  table.insert(info, "Winbar (breadcrumb):")
  local winbar = vim.wo[win].winbar
  if winbar and winbar ~= "" then
    local winbar_plugin = gather.get_winbar_plugin(win)
    table.insert(info, "   Set: yes")
    table.insert(info, string.format("   -> Plugin: %s", winbar_plugin or "unknown"))
    local display_winbar = winbar:gsub("%%#%w+#", ""):gsub("%%*", "")
    if #display_winbar > 50 then
      display_winbar = display_winbar:sub(1, 47) .. "..."
    end
    table.insert(info, string.format("   Content: %s", display_winbar))
  else
    table.insert(info, "   Set: no")
  end

  table.insert(info, "")

  local sign_info = gather.get_sign_info(buf)
  table.insert(info, "Sign Column:")
  if #sign_info > 0 then
    for _, s in ipairs(sign_info) do
      local plugin_str = s.plugin and string.format(" -> %s", s.plugin) or ""
      table.insert(info, string.format("   [%s]%s", s.group, plugin_str))
    end
  else
    table.insert(info, "   No signs in this buffer")
  end

  table.insert(info, "")

  local statusline = vim.o.statusline
  table.insert(info, "Statusline:")
  if statusline and statusline ~= "" then
    local sl_plugin = gather.guess_statusline_plugin(statusline)
    table.insert(info, string.format("   -> Plugin: %s", sl_plugin or "native"))
  else
    table.insert(info, "   Using native statusline")
  end

  local tabline = vim.o.tabline
  table.insert(info, "")
  table.insert(info, "Tabline:")
  if tabline and tabline ~= "" then
    local tl_plugin = gather.guess_tabline_plugin(tabline)
    table.insert(info, string.format("   -> Plugin: %s", tl_plugin or "native"))
  else
    local showtabline = vim.o.showtabline
    table.insert(info, string.format("   Using native tabline (showtabline=%d)", showtabline))
  end

  table.insert(info, "")
  table.insert(info, "Press 'q' or <Esc> to close")

  return info
end

function M.show_in_float(info)
  local width = 50
  local height = #info
  local max_height = math.floor(vim.o.lines * 0.8)
  if height > max_height then
    height = max_height
  end

  local win, buf = float_window.create(info, {
    width = width,
    height = height,
    position = "center",
    enter = true,
    title = " Inspector ",
    title_pos = "center",
    modifiable = false,
  })

  if win then
    local close = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
  end
end

return M
