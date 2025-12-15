# who-called.nvim

Neovim plugin to visually debug which plugin is causing notifications, UI elements, and diagnostics.

## Features

- **Hooks vim.notify**: Automatically prepends `[plugin-name]` to notifications
- **Tracks floating windows**: Records which plugin creates floating windows
- **Tracks LSP diagnostics**: Shows diagnostic source information
- **History viewer**: `:WhoCalledHistory` command to view all tracked events
- **Configurable**: Enable/disable specific tracking features

## Installation

Using lazy.nvim:

```lua
{
  "shabaraba/who-called.nvim",
  dev = true,  -- if using local development
  config = function()
    require("who-called").setup({
      enabled = false,           -- disabled by default
      history_limit = 100,
      show_in_notify = true,
      track_notify = true,
      track_windows = true,
      track_diagnostics = true,
    })
  end,
}
```

## Usage

### Commands

- `:WhoCalled` - Enable tracking
- `:WhoCalledDisable` - Disable tracking
- `:WhoCalledToggle` - Toggle tracking
- `:WhoCalledHistory` - Show history viewer
- `:WhoCalledClear` - Clear history
- `:WhoCalledStats` - Show statistics

### Programmatic Usage

```lua
local who_called = require("who-called")

who_called.setup({ enabled = false })
who_called.enable()
who_called.disable()
who_called.show_history()
who_called.clear_history()
who_called.stats()
```

## Configuration

```lua
require("who-called").setup({
  enabled = false,           -- Default: disabled
  history_limit = 100,       -- Maximum history entries
  show_in_notify = true,     -- Prepend [plugin-name] to notifications
  track_notify = true,       -- Track vim.notify calls
  track_windows = true,      -- Track floating window creation
  track_diagnostics = true,  -- Track LSP diagnostics
})
```

## How It Works

1. **vim.notify hooking**: Replaces vim.notify to capture call stack and extract plugin name
2. **Stack trace analysis**: Uses debug.getinfo() to determine caller
3. **lazy.nvim integration**: Maps file paths to plugin names using lazy.nvim's plugin registry
4. **History tracking**: Maintains a circular buffer of tracked events

## Architecture

```
who-called/
├── config.lua      - Settings management
├── resolver.lua    - File path → plugin name resolution
├── history.lua     - Event history
├── hooks/
│   ├── notify.lua
│   ├── window.lua
│   └── diagnostic.lua
├── ui.lua          - History viewer UI
└── init.lua        - Main module
```

## Performance Considerations

- Tracking is disabled by default to avoid overhead
- Enable only when debugging
- Stack trace collection happens on every notification/window creation when enabled
- History is capped at 100 entries by default

## Limitations

- Only works with plugins managed by lazy.nvim
- Diagnostic tracking is approximate (uses source field)
- Window tracking may miss some edge cases

## License

MIT
