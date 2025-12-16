-- Winbar: winbarプラグイン検出

local M = {}

local loaded_plugins = require("who-called.utils.loaded-plugins")

local function guess_from_pattern(winbar)
  if not winbar or winbar == "" then
    return nil
  end

  if winbar:match("NavicIcons") or winbar:match("[Nn]avic") then
    return "nvim-navic (or barbecue.nvim)"
  end
  if winbar:match("barbecue") or winbar:match("Barbecue") then
    return "barbecue.nvim"
  end
  if winbar:match("DropBar") or winbar:match("dropbar") then
    return "dropbar.nvim"
  end
  if winbar:match("LspsagaWinbar") or winbar:match("[Ss]aga") then
    return "lspsaga.nvim"
  end
  if winbar:match("Aerial") or winbar:match("aerial") then
    return "aerial.nvim"
  end
  if winbar:match("Incline") or winbar:match("incline") then
    return "incline.nvim"
  end
  if winbar:match("") or winbar:match("") or winbar:match("") then
    return "breadcrumb plugin (navic/barbecue/dropbar)"
  end

  return nil
end

local function guess_from_loaded()
  if loaded_plugins.is_loaded("barbecue.nvim") then
    return "barbecue.nvim"
  end
  if loaded_plugins.is_loaded("dropbar.nvim") then
    return "dropbar.nvim"
  end
  if loaded_plugins.is_loaded("nvim-navic") then
    return "nvim-navic"
  end
  if loaded_plugins.is_loaded("incline.nvim") then
    return "incline.nvim"
  end
  if loaded_plugins.is_loaded("lspsaga.nvim") then
    return "lspsaga.nvim (winbar feature)"
  end
  return nil
end

function M.get_plugin(win)
  local winbar = vim.wo[win].winbar
  if not winbar or winbar == "" then
    return nil
  end

  local ok, tracked = pcall(vim.api.nvim_win_get_var, win, "who_called_winbar")
  if ok and tracked then
    return tracked .. " (tracked)"
  end

  local ok2, option_hook = pcall(require, "who-called.hooks.option")
  if ok2 and option_hook.resolve_from_highlight_groups then
    local from_hl = option_hook.resolve_from_highlight_groups(winbar)
    if from_hl then
      return from_hl
    end
  end

  local from_pattern = guess_from_pattern(winbar)
  if from_pattern then
    return from_pattern
  end

  local from_loaded = guess_from_loaded()
  if from_loaded then
    return from_loaded
  end

  return "custom plugin"
end

function M.has_winbar(win)
  local winbar = vim.wo[win].winbar
  return winbar and winbar ~= ""
end

return M
