-- Hover Info Gather: 各UI要素の情報を収集

local M = {}

local sign = require("who-called.utils.sign")
local winbar = require("who-called.utils.winbar")
local lsp = require("who-called.utils.lsp")
local treesitter = require("who-called.utils.treesitter")
local namespace = require("who-called.utils.namespace")
local plugin_guess = require("who-called.utils.plugin-guess")

function M.get_sign_info(buf, line)
  return sign.get_info_at_line(buf, line)
end

function M.get_number_info(win)
  local has_number = vim.wo[win].number
  local has_rnu = vim.wo[win].relativenumber

  if has_number and has_rnu then
    return "hybrid number (native)"
  elseif has_number then
    return "number (native)"
  elseif has_rnu then
    return "relativenumber (native)"
  end
  return nil
end

function M.get_fold_info(win)
  local foldmethod = vim.wo[win].foldmethod
  local info = { foldmethod = foldmethod }

  if foldmethod == "expr" then
    local foldexpr = vim.wo[win].foldexpr
    if foldexpr:match("nvim_treesitter") then
      info.plugin = "nvim-treesitter"
    elseif foldexpr:match("ufo") then
      info.plugin = "nvim-ufo"
    end
  end

  return info
end

function M.get_winbar_info(win)
  return winbar.get_plugin(win)
end

function M.get_extmark_info(buf, line)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf, -1, { line - 1, 0 }, { line - 1, -1 }, { details = true })

  local plugins = {}
  for _, mark in ipairs(extmarks) do
    local ns_id = mark[4] and mark[4].ns_id or nil
    if ns_id then
      local plugin = namespace.to_plugin(ns_id)
      if plugin and not vim.tbl_contains(plugins, plugin) then
        table.insert(plugins, plugin)
      end
    end
  end

  return #plugins > 0 and plugins or nil
end

function M.get_lsp_info(buf)
  return lsp.get_clients(buf)
end

function M.get_treesitter_info(buf)
  local info = treesitter.get_info(buf)
  if info then
    return "nvim-treesitter (" .. info.lang .. ")"
  end
  return nil
end

function M.get_floating_info(win, buf, config)
  local info = {}

  local plugin = plugin_guess.from_vars(win, buf)
  if not plugin then
    local ft = vim.bo[buf].filetype
    if ft and ft ~= "" then
      plugin = plugin_guess.from_filetype(buf)
    end
  end
  if not plugin then
    plugin = plugin_guess.from_bufname(buf)
  end

  info.plugin = plugin

  if config and config.title then
    local title = config.title
    if type(title) == "string" then
      info.title = title
    elseif type(title) == "table" and #title > 0 then
      local first = title[1]
      if type(first) == "string" then
        info.title = first
      elseif type(first) == "table" and first[1] then
        info.title = first[1]
      end
    end
  end

  return info
end

return M
