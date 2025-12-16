-- Winbar: winbarプラグイン検出

local M = {}

function M.get_plugin(win)
  local winbar = vim.wo[win].winbar
  if not winbar or winbar == "" then
    return nil
  end

  -- 1. フックで追跡された情報を確認
  local ok, tracked = pcall(vim.api.nvim_win_get_var, win, "who_called_winbar")
  if ok and tracked then
    return tracked .. " (tracked)"
  end

  -- 2. ハイライトグループ名から汎用的に推測
  local ok2, option_hook = pcall(require, "who-called.hooks.option")
  if ok2 and option_hook.resolve_from_highlight_groups then
    local from_hl = option_hook.resolve_from_highlight_groups(winbar)
    if from_hl then
      return from_hl
    end
  end

  return nil
end

function M.has_winbar(win)
  local winbar = vim.wo[win].winbar
  return winbar and winbar ~= ""
end

return M
