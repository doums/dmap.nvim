## dmap.nvim

Small companion tool providing a subtle overview of LSP
diagnostics, with one click navigation

<img src="https://user-images.githubusercontent.com/6359431/211436106-c6d0e78d-1499-4788-9add-79b7b9208849.gif" width="700">

### Why?

This plugin is heavily inspired by my experience using JetBrains
IDE. There are marks on the right side of the editor tab
to highlight code diagnostic presence, in a very non-intrusive
but subtle way.
This design provides a quick overview of the code state.
A simple click on a mark "teleport" you to the corresponding
diagnostic, making this feature rather simple but very efficient.

### Install

⚠ Among other this plugin uses the new
[iterator](https://github.com/neovim/neovim/pull/23029) interface.
Only neovim from v`0.10` is supported.

Use your plugin manager

```lua
require('paq')({
  -- ...
  'doums/dmap.nvim',
})
```

### Configuration

The configuration is optional and can be partially overridden.

```lua
require('dmap').setup({
  -- highlight groups used for diagnostic marks
  -- by default link to corresponding `DiagnosticSign*` groups
  d_hl = {
    hint = 'dmapHint',
    info = 'dmapInfo',
    warn = 'dmapWarn',
    error = 'dmapError',
  },
  -- highlight group used for the diagnostic window
  -- by default link to `NormalFloat`
  win_hl = 'dmapWin',
  -- text used for diagnostic marks
  -- ⚠ the text must be one character long
  d_mark = {
    hint = '╸',
    info = '╸',
    warn = '╸',
    error = '╸',
  },
  -- max height of the diagnostic window
  -- if not set defaults to the height of the reference window
  -- must be positive
  win_max_height = nil,
  -- alignment of the diagnostic window relative to the reference window
  -- `left` | `right`
  win_align = 'right',
  -- horizontal offset (in character cell) of the diagnostic window
  -- must be positive
  win_h_offset = 1,
  -- vertical offset (in character cell) of the diagnostic window
  -- must be positive
  win_v_offset = 1,
  -- ignore these diagnostic sources
  ignore_sources = {},
  -- ignore these filetypes buffer
  ignore_filetypes = { 'NvimTree' },
  -- severity option passed to `vim.diagnostic.get()` (`:h diagnostic-severity`)
  severity = nil,
  -- override arguments passed to `nvim_open_win` (see `:h nvim_open_win`)
  -- ⚠ can potentially break the plugin, use at your own risk
  nvim_float_api = nil,
})
```

All default configuration values are listed
[here](https://github.com/doums/dmap.nvim/blob/main/lua/dmap/config.lua).

### License

Mozilla Public License 2.0
