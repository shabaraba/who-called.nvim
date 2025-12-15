-- Inspector: 現在のウィンドウ/バッファの詳細情報を表示

local M = {}
local resolver = require("who-called.resolver")

-- filetype からプラグインを推測するマッピング（resolver と共有）
local filetype_hints = {
  -- File explorers
  ["oil"] = "oil.nvim",
  ["neo-tree"] = "neo-tree.nvim",
  ["NvimTree"] = "nvim-tree.lua",
  ["dirvish"] = "vim-dirvish",
  ["fern"] = "fern.vim",
  -- Telescope
  ["TelescopePrompt"] = "telescope.nvim",
  ["TelescopeResults"] = "telescope.nvim",
  -- Fuzzy finders
  ["fzf"] = "fzf.vim or fzf-lua",
  -- Git
  ["fugitive"] = "vim-fugitive",
  ["gitcommit"] = "git (native)",
  ["NeogitStatus"] = "neogit",
  ["DiffviewFiles"] = "diffview.nvim",
  -- LSP
  ["lspinfo"] = "nvim-lspconfig",
  ["lspsagaoutline"] = "lspsaga.nvim",
  ["lspsagafinder"] = "lspsaga.nvim",
  ["saga_codeaction"] = "lspsaga.nvim",
  ["Outline"] = "outline.nvim or symbols-outline.nvim",
  ["aerial"] = "aerial.nvim",
  -- DAP
  ["dapui_scopes"] = "nvim-dap-ui",
  ["dapui_breakpoints"] = "nvim-dap-ui",
  ["dapui_stacks"] = "nvim-dap-ui",
  ["dapui_watches"] = "nvim-dap-ui",
  ["dap-repl"] = "nvim-dap",
  -- Package managers
  ["lazy"] = "lazy.nvim",
  ["mason"] = "mason.nvim",
  ["packer"] = "packer.nvim",
  -- Terminal
  ["toggleterm"] = "toggleterm.nvim",
  ["terminal"] = "native terminal",
  -- Diagnostics
  ["trouble"] = "trouble.nvim",
  ["qf"] = "quickfix (native)",
  -- Notifications
  ["notify"] = "nvim-notify",
  ["noice"] = "noice.nvim",
  -- Completion
  ["cmp_docs"] = "nvim-cmp",
  ["cmp_menu"] = "nvim-cmp",
  -- Help
  ["help"] = "native help",
  ["man"] = "native man",
  -- Markdown preview
  ["markdown"] = "native or plugin",
  ["Glance"] = "glance.nvim",
  -- Testing
  ["neotest-summary"] = "neotest",
  ["neotest-output"] = "neotest",
  -- Other
  ["alpha"] = "alpha-nvim",
  ["dashboard"] = "dashboard-nvim",
  ["startify"] = "vim-startify",
  ["Navbuddy"] = "nvim-navbuddy",
  ["undotree"] = "undotree",
  ["spectre_panel"] = "nvim-spectre",
}

-- winbar 設定からプラグインを推測
local function guess_winbar_plugin(winbar)
  if not winbar or winbar == "" then
    return nil
  end

  -- 一般的な winbar プラグインのパターン
  if winbar:match("navic") or winbar:match("NavicIcons") then
    return "nvim-navic"
  end
  if winbar:match("barbecue") then
    return "barbecue.nvim"
  end
  if winbar:match("dropbar") then
    return "dropbar.nvim"
  end
  if winbar:match("lspsaga") or winbar:match("Lspsaga") then
    return "lspsaga.nvim"
  end
  if winbar:match("aerial") then
    return "aerial.nvim"
  end
  if winbar:match("%%#") then
    return "custom (uses highlight groups)"
  end

  return "unknown"
end

-- statusline 設定からプラグインを推測
local function guess_statusline_plugin(statusline)
  if not statusline or statusline == "" then
    return nil
  end

  if statusline:match("lualine") then
    return "lualine.nvim"
  end
  if statusline:match("airline") then
    return "vim-airline"
  end
  if statusline:match("lightline") then
    return "lightline.vim"
  end
  if statusline:match("galaxyline") then
    return "galaxyline.nvim"
  end
  if statusline:match("feline") then
    return "feline.nvim"
  end
  if statusline:match("heirline") then
    return "heirline.nvim"
  end

  return "custom or native"
end

-- tabline 設定からプラグインを推測
local function guess_tabline_plugin(tabline)
  if not tabline or tabline == "" then
    return nil
  end

  if tabline:match("bufferline") then
    return "bufferline.nvim"
  end
  if tabline:match("barbar") then
    return "barbar.nvim"
  end
  if tabline:match("tabby") then
    return "tabby.nvim"
  end
  if tabline:match("cokeline") then
    return "nvim-cokeline"
  end

  return "custom or native"
end

-- 現在のウィンドウ/バッファを調査
function M.inspect()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()

  local info = {
    "╭─────────────────────────────────────────╮",
    "│        who-called.nvim Inspector        │",
    "╰─────────────────────────────────────────╯",
    "",
  }

  -- Buffer info
  local bufname = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype
  local buftype = vim.bo[buf].buftype

  table.insert(info, "📄 Buffer Information:")
  table.insert(info, string.format("   Number: %d", buf))
  table.insert(info, string.format("   Name: %s", bufname ~= "" and bufname or "(empty)"))
  table.insert(info, string.format("   Filetype: %s", ft ~= "" and ft or "(none)"))
  table.insert(info, string.format("   Buftype: %s", buftype ~= "" and buftype or "(normal)"))

  -- Plugin guess from filetype
  local ft_plugin = filetype_hints[ft]
  if ft_plugin then
    table.insert(info, string.format("   → Plugin (from ft): %s", ft_plugin))
  end

  -- Plugin guess from buffer name scheme
  local bufname_plugin = resolver.resolve_from_buffer(buf)
  if bufname_plugin and bufname_plugin ~= ft_plugin then
    table.insert(info, string.format("   → Plugin (from name): %s", bufname_plugin))
  end

  table.insert(info, "")

  -- Window info
  local win_config = vim.api.nvim_win_get_config(win)
  local is_float = win_config.relative ~= ""

  table.insert(info, "🪟 Window Information:")
  table.insert(info, string.format("   Number: %d", win))
  table.insert(info, string.format("   Type: %s", is_float and "floating" or "normal"))

  if is_float then
    table.insert(info, string.format("   Relative: %s", win_config.relative))
    if win_config.title then
      local title = type(win_config.title) == "string" and win_config.title or vim.inspect(win_config.title)
      table.insert(info, string.format("   Title: %s", title))
    end
    if win_config.border then
      local border = type(win_config.border) == "string" and win_config.border or "custom"
      table.insert(info, string.format("   Border: %s", border))
    end
  end

  -- who_called_plugin variable
  local ok, plugin_var = pcall(vim.api.nvim_win_get_var, win, "who_called_plugin")
  if ok and plugin_var then
    table.insert(info, string.format("   → Plugin (tracked): %s", plugin_var))
  end

  table.insert(info, "")

  -- Winbar
  local winbar = vim.wo[win].winbar
  table.insert(info, "🍞 Winbar (breadcrumb):")
  if winbar and winbar ~= "" then
    local winbar_plugin = guess_winbar_plugin(winbar)
    table.insert(info, string.format("   Set: yes"))
    table.insert(info, string.format("   → Plugin: %s", winbar_plugin or "unknown"))
    -- Show truncated winbar content
    local display_winbar = winbar:gsub("%%#%w+#", ""):gsub("%%*", "")
    if #display_winbar > 50 then
      display_winbar = display_winbar:sub(1, 47) .. "..."
    end
    table.insert(info, string.format("   Content: %s", display_winbar))
  else
    table.insert(info, "   Set: no")
  end

  table.insert(info, "")

  -- Statusline (global)
  local statusline = vim.o.statusline
  table.insert(info, "📊 Statusline:")
  if statusline and statusline ~= "" then
    local sl_plugin = guess_statusline_plugin(statusline)
    table.insert(info, string.format("   → Plugin: %s", sl_plugin or "native"))
  else
    table.insert(info, "   Using native statusline")
  end

  -- Tabline (global)
  local tabline = vim.o.tabline
  table.insert(info, "")
  table.insert(info, "📑 Tabline:")
  if tabline and tabline ~= "" then
    local tl_plugin = guess_tabline_plugin(tabline)
    table.insert(info, string.format("   → Plugin: %s", tl_plugin or "native"))
  else
    local showtabline = vim.o.showtabline
    table.insert(info, string.format("   Using native tabline (showtabline=%d)", showtabline))
  end

  -- Display
  table.insert(info, "")
  table.insert(info, "─────────────────────────────────────────")

  -- Use vim.notify or print
  local result = table.concat(info, "\n")
  print(result)
end

return M
