-- Hover Mouse: マウスイベント処理

local M = {}

local state = require("who-called.hover.state")
local detect = require("who-called.hover.detect")
local format = require("who-called.hover.format")
local float_window = require("who-called.ui.float-window")

local HOVER_DELAY_MS = 300

local function close_hover()
  local win = state.get_hover_win()
  local buf = state.get_hover_buf()
  float_window.close(win, buf)
  state.set("hover_win", nil)
  state.set("hover_buf", nil)
end

local function show_hover(pos, lines)
  close_hover()

  local row = pos.screenrow
  local col = pos.screencol + 2

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.max(width, 20)

  if col + width > vim.o.columns then
    col = vim.o.columns - width - 2
  end

  local win, buf = float_window.create(lines, {
    row = row,
    col = col,
    filetype = "who-called-hover",
    focusable = false,
    zindex = 250,
    winblend = 10,
  })

  if win then
    state.set("hover_win", win)
    state.set("hover_buf", buf)
    vim.cmd("redraw")
  end
end

function M.on_mouse_move()
  if vim.g.who_called_debug then
    vim.schedule(function()
      print("MouseMove: mode=" .. vim.fn.mode())
    end)
  end

  local timer = state.get("hover_timer")
  if timer then
    timer:stop()
  end

  vim.schedule(close_hover)

  timer = vim.uv.new_timer()
  state.set("hover_timer", timer)

  timer:start(HOVER_DELAY_MS, 0, vim.schedule_wrap(function()
    local pos = vim.fn.getmousepos()

    if vim.g.who_called_debug then
      print("getmousepos: winid=" .. pos.winid .. " line=" .. pos.line)
    end

    if pos.winid == 0 then
      return
    end

    local ui_info = detect.detect_ui_element(pos)
    local lines = format.format_hover_info(ui_info)

    if vim.g.who_called_debug then
      print("ui_info:", ui_info and ui_info.element or "nil", "lines:", lines and #lines or "nil")
    end

    if lines then
      show_hover(pos, lines)
    end
  end))
end

function M.setup_keymaps()
  vim.keymap.set({ "n", "v", "i", "c" }, "<MouseMove>", function()
    M.on_mouse_move()
    return "<MouseMove>"
  end, { expr = true, silent = true, desc = "who-called hover" })
end

function M.remove_keymaps()
  pcall(vim.keymap.del, { "n", "v", "i", "c" }, "<MouseMove>")
end

function M.cleanup()
  local timer = state.get("hover_timer")
  if timer then
    timer:stop()
    timer:close()
    state.set("hover_timer", nil)
  end
  close_hover()
end

return M
