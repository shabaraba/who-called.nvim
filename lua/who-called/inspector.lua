-- Inspector: 現在のウィンドウ/バッファの詳細情報を表示

local M = {}
local resolver = require("who-called.resolver")

-- サイングループからプラグインを推測
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

-- filetype からプラグインを推測するマッピング（resolver と共有）
local filetype_hints = {
  -- pile.nvim
  ["pile"] = "pile.nvim",
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

  -- 一般的な winbar プラグインのパターン（highlight group名で判定）
  if winbar:match("NavicIcons") or winbar:match("Navic") then
    return "nvim-navic (or barbecue.nvim)"
  end
  if winbar:match("barbecue") or winbar:match("Barbecue") then
    return "barbecue.nvim"
  end
  if winbar:match("DropBar") or winbar:match("dropbar") then
    return "dropbar.nvim"
  end
  if winbar:match("LspsagaWinbar") or winbar:match("Lspsaga") then
    return "lspsaga.nvim"
  end
  if winbar:match("Aerial") or winbar:match("aerial") then
    return "aerial.nvim"
  end
  -- breadcrumb-like patterns (icons with separators)
  if winbar:match("") or winbar:match("") or winbar:match("") then
    return "breadcrumb plugin (navic/barbecue/dropbar)"
  end
  -- incline.nvim pattern
  if winbar:match("Incline") then
    return "incline.nvim"
  end

  return "custom plugin"
end

-- ロードされているプラグインをチェック
local function get_loaded_plugins()
  local loaded = {}
  local ok, lazy = pcall(require, "lazy")
  if ok then
    local plugins = lazy.plugins()
    for _, plugin in ipairs(plugins) do
      if plugin._.loaded then
        loaded[plugin.name] = true
      end
    end
  end
  return loaded
end

-- statusline 設定からプラグインを推測
local function guess_statusline_plugin(statusline)
  -- まずロードされているプラグインから推測
  local loaded = get_loaded_plugins()
  if loaded["lualine.nvim"] then
    return "lualine.nvim"
  end
  if loaded["heirline.nvim"] then
    return "heirline.nvim"
  end
  if loaded["feline.nvim"] then
    return "feline.nvim"
  end

  if not statusline or statusline == "" then
    return "native"
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

  return "custom"
end

-- tabline 設定からプラグインを推測
local function guess_tabline_plugin(tabline)
  -- ロードされているプラグインから推測
  local loaded = get_loaded_plugins()
  if loaded["bufferline.nvim"] then
    return "bufferline.nvim"
  end
  if loaded["barbar.nvim"] then
    return "barbar.nvim"
  end
  if loaded["tabby.nvim"] then
    return "tabby.nvim"
  end
  if loaded["nvim-cokeline"] then
    return "nvim-cokeline"
  end

  if not tabline or tabline == "" then
    return nil
  end

  if tabline:match("bufferline") or tabline:match("Bufferline") then
    return "bufferline.nvim"
  end
  if tabline:match("barbar") or tabline:match("Barbar") then
    return "barbar.nvim"
  end
  if tabline:match("tabby") then
    return "tabby.nvim"
  end
  if tabline:match("cokeline") then
    return "nvim-cokeline"
  end

  return "custom"
end

-- サインカラムの情報を取得
local function get_sign_info(bufnr)
  local signs = {}
  local placed = vim.fn.sign_getplaced(bufnr, { group = "*" })

  if placed and placed[1] and placed[1].signs then
    for _, sign in ipairs(placed[1].signs) do
      local group = sign.group or "default"
      local name = sign.name or "unknown"

      -- グループ名からプラグインを推測
      local plugin = nil
      for pattern, plug in pairs(signgroup_to_plugin) do
        if group:match(pattern) or name:match(pattern) then
          plugin = plug
          break
        end
      end

      if not signs[group] then
        signs[group] = {
          plugin = plugin,
          count = 0,
          names = {},
        }
      end
      signs[group].count = signs[group].count + 1
      if not vim.tbl_contains(signs[group].names, name) then
        table.insert(signs[group].names, name)
      end
    end
  end

  return signs
end

-- winbar のプラグインをロード状況から推測
local function guess_winbar_from_loaded()
  local loaded = get_loaded_plugins()
  if loaded["barbecue.nvim"] then
    return "barbecue.nvim"
  end
  if loaded["dropbar.nvim"] then
    return "dropbar.nvim"
  end
  if loaded["nvim-navic"] then
    return "nvim-navic"
  end
  if loaded["incline.nvim"] then
    return "incline.nvim"
  end
  if loaded["lspsaga.nvim"] then
    return "lspsaga.nvim (winbar feature)"
  end
  return nil
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
    -- まずパターンマッチで推測、ダメならロード済みプラグインから推測
    local winbar_plugin = guess_winbar_plugin(winbar)
    if winbar_plugin == "custom plugin" then
      local loaded_plugin = guess_winbar_from_loaded()
      if loaded_plugin then
        winbar_plugin = loaded_plugin
      end
    end
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

  -- Sign column
  local sign_info = get_sign_info(buf)
  table.insert(info, "🔖 Sign Column:")
  if next(sign_info) then
    for group, data in pairs(sign_info) do
      local plugin_str = data.plugin and string.format(" → %s", data.plugin) or ""
      table.insert(info, string.format("   [%s] %d signs%s", group, data.count, plugin_str))
      if #data.names > 0 and #data.names <= 3 then
        table.insert(info, string.format("      Names: %s", table.concat(data.names, ", ")))
      end
    end
  else
    table.insert(info, "   No signs in this buffer")
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
  table.insert(info, "Press 'q' or <Esc> to close")

  -- フローティングウィンドウで表示
  local width = 50
  local height = #info
  local max_height = math.floor(vim.o.lines * 0.8)
  if height > max_height then
    height = max_height
  end

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, info)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Inspector ",
    title_pos = "center",
  })

  -- キーマップで閉じる
  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

return M
