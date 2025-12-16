-- Hover Format: 表示内容のフォーマット

local M = {}

local info_gather = require("who-called.hover.info-gather")

function M.format_hover_info(ui_info)
  if not ui_info then
    return nil
  end

  local lines = {}
  local element = ui_info.element
  local buf = ui_info.buf
  local line = ui_info.line
  local win = ui_info.win

  table.insert(lines, "--- " .. element:upper():gsub("_", " ") .. " ---")

  if element == "sign_column" then
    local signs = info_gather.get_sign_info(buf, line)
    if signs and #signs > 0 then
      for _, plugin in ipairs(signs) do
        table.insert(lines, " sign: " .. plugin)
      end
    else
      table.insert(lines, " (no signs)")
    end

  elseif element == "number_column" then
    local number_info = info_gather.get_number_info(win)
    if number_info then
      table.insert(lines, " num: " .. number_info)
    end

  elseif element == "fold_column" then
    local fold_info = info_gather.get_fold_info(win)
    table.insert(lines, " foldmethod: " .. fold_info.foldmethod)
    if fold_info.plugin then
      table.insert(lines, " -> " .. fold_info.plugin)
    end

  elseif element == "winbar" then
    local plugin = info_gather.get_winbar_info(win)
    if plugin then
      table.insert(lines, " winbar: " .. plugin)
    end

  elseif element == "buffer" then
    local extmarks = info_gather.get_extmark_info(buf, line)
    if extmarks and #extmarks > 0 then
      table.insert(lines, " Extmarks:")
      for _, plugin in ipairs(extmarks) do
        table.insert(lines, "   * " .. plugin)
      end
    end

    local lsp_clients = info_gather.get_lsp_info(buf)
    if lsp_clients and #lsp_clients > 0 then
      table.insert(lines, " LSP:")
      for _, name in ipairs(lsp_clients) do
        table.insert(lines, "   * " .. name)
      end
    end

    local ts_info = info_gather.get_treesitter_info(buf)
    if ts_info then
      table.insert(lines, " Syntax:")
      table.insert(lines, "   * " .. ts_info)
    end

    local signs = info_gather.get_sign_info(buf, line)
    if signs and #signs > 0 then
      table.insert(lines, " Signs (this line):")
      for _, plugin in ipairs(signs) do
        table.insert(lines, "   * " .. plugin)
      end
    end

  elseif element == "floating" then
    local float_info = info_gather.get_floating_info(win, buf, ui_info.config)

    if float_info.title then
      table.insert(lines, " title: " .. float_info.title)
    end
    if float_info.plugin then
      table.insert(lines, " plugin: " .. float_info.plugin)
    else
      table.insert(lines, " plugin: (unknown)")
    end
  end

  if #lines <= 1 then
    return nil
  end

  return lines
end

return M
