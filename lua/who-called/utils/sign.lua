-- Sign: サイン情報を取得・プラグイン解決

local M = {}

local namespace = require("who-called.utils.namespace")

local signgroup_to_plugin = {
  ["gitsigns_vimfn_signs_"] = "gitsigns.nvim",
  ["gitsigns_extmark_signs_"] = "gitsigns.nvim",
  ["GitGutter"] = "vim-gitgutter",
  ["DiagnosticSign"] = "LSP Diagnostic (native)",
  ["DapBreakpoint"] = "nvim-dap",
  ["DapStopped"] = "nvim-dap",
  ["neotest"] = "neotest",
  ["coverage"] = "nvim-coverage",
  ["todo-signs"] = "todo-comments.nvim",
}

function M.group_to_plugin(group)
  if not group or group == "" then
    return nil
  end

  for pattern, plugin in pairs(signgroup_to_plugin) do
    if group:match(pattern) then
      return plugin
    end
  end

  return group
end

function M.get_info_at_line(buf, line)
  local plugins = {}

  local ok, result = pcall(vim.fn.sign_getplaced, buf, { lnum = line })
  if ok and result and result[1] and result[1].signs then
    for _, sign in ipairs(result[1].signs) do
      local plugin = M.group_to_plugin(sign.group)
      if plugin and not vim.tbl_contains(plugins, plugin) then
        table.insert(plugins, plugin)
      end
    end
  end

  local ok2, extmarks = pcall(vim.api.nvim_buf_get_extmarks,
    buf, -1, { line - 1, 0 }, { line - 1, -1 }, { details = true })
  if ok2 and extmarks then
    for _, mark in ipairs(extmarks) do
      local details = mark[4]
      if details and (details.sign_text or details.sign_hl_group) then
        local plugin = nil
        if details.ns_id then
          plugin = namespace.to_plugin(details.ns_id)
        end
        if not plugin and details.sign_hl_group then
          local hl = details.sign_hl_group
          local prefix = hl:match("^(%u%l+%u?%l*)")
          if prefix then
            plugin = prefix .. " (from hl)"
          end
        end
        if plugin and not vim.tbl_contains(plugins, plugin) then
          table.insert(plugins, plugin)
        end
      end
    end
  end

  if #plugins == 0 then
    return nil
  end
  return plugins
end

function M.get_all_plugins(buf)
  local plugins = {}
  local seen = {}

  local ok, placed = pcall(vim.fn.sign_getplaced, buf, { group = "*" })
  if ok and placed and placed[1] and placed[1].signs then
    for _, sign in ipairs(placed[1].signs) do
      local group = sign.group or "default"
      local plugin = nil
      for pattern, plug in pairs(signgroup_to_plugin) do
        if group:match(pattern) or (sign.name and sign.name:match(pattern)) then
          plugin = plug
          break
        end
      end
      local key = plugin or group
      if not seen[key] then
        seen[key] = true
        table.insert(plugins, { group = group, plugin = plugin })
      end
    end
  end

  local ok2, extmarks = pcall(vim.api.nvim_buf_get_extmarks, buf, -1, 0, -1, { details = true })
  if ok2 and extmarks then
    for _, mark in ipairs(extmarks) do
      local details = mark[4]
      if details and (details.sign_text or details.sign_hl_group) then
        local plugin = nil
        if details.ns_id then
          plugin = namespace.to_plugin(details.ns_id)
        end
        if not plugin and details.sign_hl_group then
          local hl = details.sign_hl_group
          local prefix = hl:match("^(%u%l+%u?%l*)")
          if prefix then
            plugin = prefix .. " (from hl)"
          end
        end
        if plugin and not seen[plugin] then
          seen[plugin] = true
          table.insert(plugins, { group = "extmark", plugin = plugin })
        end
      end
    end
  end

  return plugins
end

return M
