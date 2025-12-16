# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

who-called.nvim is a Neovim debugging plugin that identifies which plugin is responsible for UI elements like notifications, floating windows, diagnostics, and buffer/option changes. It relies on lazy.nvim for plugin path resolution.

## Development Commands

```bash
# Test the plugin in Neovim (from project root)
nvim --cmd "set rtp+=." -c "lua require('who-called').setup({ enabled = true })"

# Lint with luacheck (if available)
luacheck lua/
```

## Architecture

```
lua/who-called/
├── init.lua          # Entry point, setup() and enable/disable API
├── config.lua        # Configuration management with defaults
├── resolver.lua      # Core: stack trace analysis → plugin name resolution
├── history.lua       # Circular buffer for tracked events
├── hooks/
│   ├── notify.lua    # Hooks vim.notify to capture caller
│   ├── window.lua    # Tracks nvim_open_win for floating windows
│   ├── diagnostic.lua # Tracks vim.diagnostic events
│   ├── buffer.lua    # Tracks buffer creation/modification
│   └── option.lua    # Tracks option changes (winbar, etc.)
├── ui.lua            # History viewer floating window
├── inspector.lua     # Static inspection of current window/buffer
├── inspector-live.lua # Real-time inspector (follows cursor)
└── hover.lua         # Mouse hover tooltips showing plugin info

plugin/
└── who-called.lua    # User commands
```

## Commands

| Command | Description |
|---------|-------------|
| `:WhoCalled` | Toggle all features (tracking + live inspector + hover) |
| `:WhoCalledInspect` | One-time inspection of current window/buffer |
| `:WhoCalledHistory` | Show history of all tracked events |
| `:WhoCalledClear` | Clear the event history |

## Key Patterns

### Plugin Resolution Flow
1. `resolver.resolve(level)` walks the debug stack trace using `debug.getinfo()`
2. Extracts file paths and matches against lazy.nvim's plugin directory (`~/.local/share/nvim/lazy/`)
3. Skips "utility plugins" (plenary.nvim, nui.nvim, nvim-notify) to find the actual caller
4. Falls back to buffer name patterns for special schemes (oil://, neo-tree://, etc.)

### Hook Registration Pattern
Each hook module follows this structure:
- `enable()`: Save original function, replace with wrapped version that calls resolver
- `disable()`: Restore original function
- `is_hooked()`: Return current state
- Tracked events are stored via `history.add()`

### Inspector Modes
- **Static** (`WhoCalledInspect`): One-time snapshot of current window/buffer
- **Live** (via `WhoCalled`): Persistent floating window that updates on cursor movement
- **Hover** (via `WhoCalled`): Mouse-triggered tooltips via `<MouseMove>` mapping

## Configuration Defaults

```lua
{
  enabled = false,        -- Start with hooks disabled
  history_limit = 100,    -- Max tracked events
  show_in_notify = true,  -- Prepend [plugin-name] to notifications
  track_notify = true,
  track_windows = true,
  track_diagnostics = true,
  track_buffers = true,
  hover = false,          -- Auto-start hover mode on setup
  live_inspector = false, -- Auto-start live inspector on setup
}
```

## Window/Buffer Variables

The plugin sets these variables for tracking:
- `vim.w.who_called_plugin`: Plugin that created the window
- `vim.b.who_called_plugin`: Plugin that created/modified the buffer
- `vim.w.who_called_winbar`: Plugin that set the winbar

## Language

- Code comments are in Japanese
- Commit messages should be in English (Semantic Commit Messages)
