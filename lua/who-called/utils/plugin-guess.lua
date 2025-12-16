-- Plugin Guess: ウィンドウ/バッファ変数やパターンからプラグイン推測

local M = {}

function M.from_vars(win, buf)
  local ok, win_plugin = pcall(vim.api.nvim_win_get_var, win, "who_called_plugin")
  if ok and win_plugin then
    return win_plugin .. " (tracked)"
  end

  local ok2, buf_plugin = pcall(vim.api.nvim_buf_get_var, buf, "who_called_plugin")
  if ok2 and buf_plugin then
    return buf_plugin .. " (tracked)"
  end

  return nil
end

function M.from_filetype(buf)
  local ft = vim.bo[buf].filetype
  if not ft or ft == "" then
    return nil
  end

  local plugin_name = ft:match("^(%u%l+)") or ft
  return plugin_name .. " (ft:" .. ft .. ")"
end

function M.from_bufname(buf)
  local bufname = vim.api.nvim_buf_get_name(buf)
  if not bufname or bufname == "" then
    return nil
  end

  if bufname:match("^oil://") then
    return "oil.nvim"
  end
  if bufname:match("^neo%-tree://") then
    return "neo-tree.nvim"
  end
  if bufname:match("^NvimTree_") then
    return "nvim-tree.lua"
  end
  if bufname:match("^fugitive://") then
    return "vim-fugitive"
  end
  if bufname:match("^gitsigns://") then
    return "gitsigns.nvim"
  end
  if bufname:match("^diffview://") then
    return "diffview.nvim"
  end

  return vim.fn.fnamemodify(bufname, ":t") .. " (bufname)"
end

function M.guess(win, buf)
  local from_vars = M.from_vars(win, buf)
  if from_vars then
    return from_vars
  end

  local from_ft = M.from_filetype(buf)
  if from_ft then
    return from_ft
  end

  local from_bufname = M.from_bufname(buf)
  if from_bufname then
    return from_bufname
  end

  return nil
end

return M
