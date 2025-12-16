-- Inspector Live: カーソル追従型のリアルタイム Inspector

local M = {}

local state = require("who-called.inspector-live.state")
local display = require("who-called.inspector-live.display")

function M.start()
  if state.is_valid() then
    vim.notify("Inspector Live already running", vim.log.levels.WARN)
    return
  end

  local win, buf = display.create_window()
  if not win then
    vim.notify("Failed to create Inspector Live window", vim.log.levels.ERROR)
    return
  end

  state.set("live_win", win)
  state.set("live_buf", buf)

  local group = vim.api.nvim_create_augroup("WhoCalledInspectorLive", { clear = true })
  state.set("autocmd_group", group)

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "CursorMoved" }, {
    group = group,
    callback = function()
      vim.schedule(display.update_display)
    end,
  })

  vim.api.nvim_create_autocmd({ "WinNew", "WinClosed", "WinScrolled" }, {
    group = group,
    callback = function()
      vim.schedule(display.update_display)
    end,
  })

  local timer = vim.loop.new_timer()
  state.set("timer", timer)

  timer:start(100, 200, vim.schedule_wrap(function()
    if state.is_valid() then
      display.update_display()
    else
      timer:stop()
      timer:close()
    end
  end))

  display.update_display()

  vim.notify("Inspector Live started", vim.log.levels.INFO)
end

function M.stop()
  local group = state.get("autocmd_group")
  if group then
    vim.api.nvim_del_augroup_by_id(group)
  end

  local timer = state.get("timer")
  if timer then
    timer:stop()
    timer:close()
  end

  display.close_window()
  state.reset()

  vim.notify("Inspector Live stopped", vim.log.levels.INFO)
end

function M.toggle()
  if state.is_valid() then
    M.stop()
  else
    M.start()
  end
end

function M.is_running()
  return state.is_valid()
end

return M
