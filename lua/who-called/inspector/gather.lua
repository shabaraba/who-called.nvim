-- Inspector Gather: ウィンドウ/バッファ情報を収集

local M = {}

local sign = require("who-called.utils.sign")
local winbar = require("who-called.utils.winbar")
local loaded_plugins = require("who-called.utils.loaded-plugins")

function M.get_buffer_info(buf)
  local bufname = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype
  local buftype = vim.bo[buf].buftype

  return {
    number = buf,
    name = bufname ~= "" and bufname or "(empty)",
    filetype = ft ~= "" and ft or "(none)",
    buftype = buftype ~= "" and buftype or "(normal)",
  }
end

function M.get_window_info(win)
  local win_config = vim.api.nvim_win_get_config(win)
  local is_float = win_config.relative ~= ""

  local info = {
    number = win,
    is_float = is_float,
    config = win_config,
  }

  if is_float then
    info.relative = win_config.relative
    if win_config.title then
      info.title = type(win_config.title) == "string"
        and win_config.title
        or vim.inspect(win_config.title)
    end
    if win_config.border then
      info.border = type(win_config.border) == "string"
        and win_config.border
        or "custom"
    end
  end

  local ok, win_plugin = pcall(vim.api.nvim_win_get_var, win, "who_called_plugin")
  if ok and win_plugin then
    info.tracked_plugin_win = win_plugin
  end

  return info
end

function M.get_sign_info(buf)
  return sign.get_all_plugins(buf)
end

function M.get_winbar_plugin(win)
  return winbar.get_plugin(win)
end

function M.guess_statusline_plugin(statusline)
  local loaded = loaded_plugins.get_all()
  if loaded["lualine.nvim"] then return "lualine.nvim" end
  if loaded["heirline.nvim"] then return "heirline.nvim" end
  if loaded["feline.nvim"] then return "feline.nvim" end

  if not statusline or statusline == "" then
    return "native"
  end

  if statusline:match("lualine") then return "lualine.nvim" end
  if statusline:match("airline") then return "vim-airline" end
  if statusline:match("lightline") then return "lightline.vim" end
  if statusline:match("galaxyline") then return "galaxyline.nvim" end
  if statusline:match("feline") then return "feline.nvim" end
  if statusline:match("heirline") then return "heirline.nvim" end

  return "custom"
end

function M.guess_tabline_plugin(tabline)
  local loaded = loaded_plugins.get_all()
  if loaded["bufferline.nvim"] then return "bufferline.nvim" end
  if loaded["barbar.nvim"] then return "barbar.nvim" end
  if loaded["tabby.nvim"] then return "tabby.nvim" end
  if loaded["nvim-cokeline"] then return "nvim-cokeline" end

  if not tabline or tabline == "" then
    return nil
  end

  if tabline:match("bufferline") or tabline:match("Bufferline") then return "bufferline.nvim" end
  if tabline:match("barbar") or tabline:match("Barbar") then return "barbar.nvim" end
  if tabline:match("tabby") then return "tabby.nvim" end
  if tabline:match("cokeline") then return "nvim-cokeline" end

  return "custom"
end

return M
