-- Inspector Live Display: 表示の作成と更新

local M = {}

local state = require("who-called.inspector-live.state")
local gather = require("who-called.inspector-live.gather")
local float_window = require("who-called.ui.float-window")

function M.format_info(info)
  if not info then
    return { " Inspector: (self) " }
  end

  local lines = {}
  local plugin_str = info.plugin or "?"
  local ft_str = info.filetype ~= "" and info.filetype or "-"
  local type_str = info.is_float and "float" or "normal"

  table.insert(lines, " -- Current --")
  table.insert(lines, string.format(" plugin: %s", plugin_str))
  table.insert(lines, string.format(" ft: %s | %s", ft_str, type_str))

  if info.bufname and info.bufname ~= "" then
    local short_name = vim.fn.fnamemodify(info.bufname, ":t")
    if #short_name > 25 then
      short_name = short_name:sub(1, 22) .. "..."
    end
    table.insert(lines, string.format(" %s", short_name))
  end

  local render_info = gather.get_rendering_info(info.win, info.buf)

  table.insert(lines, "")
  table.insert(lines, " -- Rendering --")

  if render_info.winbar_plugin then
    table.insert(lines, string.format(" winbar: %s", render_info.winbar_plugin))
  end

  if render_info.sign_plugins then
    for _, sp in ipairs(render_info.sign_plugins) do
      local name = sp.plugin or sp.group
      table.insert(lines, string.format(" sign: %s", name))
    end
  end

  if render_info.lsp_clients then
    for _, client in ipairs(render_info.lsp_clients) do
      table.insert(lines, string.format(" lsp: %s", client))
    end
  end

  if render_info.treesitter then
    table.insert(lines, string.format(" ts: %s", render_info.treesitter))
  end

  if info.floats and #info.floats > 0 then
    table.insert(lines, "")
    table.insert(lines, " -- Floats --")
    for _, float in ipairs(info.floats) do
      local float_plugin = float.plugin or "?"
      local float_title = float.title and (" " .. float.title) or ""
      if #float_title > 20 then
        float_title = float_title:sub(1, 17) .. "..."
      end
      table.insert(lines, string.format(" %s%s", float_plugin, float_title))
    end
  end

  return lines
end

function M.update_display()
  local live_buf = state.get_live_buf()
  local live_win = state.get_live_win()

  if not live_buf or not vim.api.nvim_buf_is_valid(live_buf) then
    return
  end
  if not live_win or not vim.api.nvim_win_is_valid(live_win) then
    return
  end

  local info = gather.get_current_info()
  local lines = M.format_info(info)

  float_window.update_content(live_buf, lines)
  float_window.resize_to_content(live_win, lines, {
    position = "bottom-right",
    min_width = 20,
  })
end

function M.create_window()
  local lines = { " Inspector Live " }
  local win, buf = float_window.create(lines, {
    position = "bottom-right",
    filetype = "who-called-inspector",
    focusable = false,
    winblend = 10,
  })

  return win, buf
end

function M.close_window()
  local live_win = state.get_live_win()
  local live_buf = state.get_live_buf()
  float_window.close(live_win, live_buf)
end

return M
