## dmap.nvim

Convenient and not disturbing overview of all LSP diagnostics,
with one click navigation

<img src="https://github.com/doums/dmap.nvim/blob/main/public/dmap.gif" width="700">

### Why?

This plugin is heavily inspired by my experience using JetBrains
IDE in which there are marks on the right side of the tab editor
for each diagnostic in the file. The key point is regarding the
marks positions the height of the editor view actually corresponds
to the full length of the buffer.
That is, this design provides an overview of all diagnostics,
regardless their location in the buffer.
A simple click on a mark "teleport" you to the corresponding
diagnostic, making this feature rather simple but very convenient
(at least for me, who said it's a shame to use the mouse anyway?).

### Install

⚠ This plugin heavily relies on the recently added `WinResized`
[event](https://github.com/neovim/neovim/pull/21161).
Only neovim from v`0.9` is supported.
For prior versions PR could be considered (if the amount of code
changes is not crazy).

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
  -- diagnostic windows height
  height = 10,
  -- highlight groups used for diagnostic marks
  -- by default link to corresponding `DiagnosticSign*` groups
  d_hl = {
    hint = 'dmapHint',
    info = 'dmapInfo',
    warn = 'dmapWarn',
    error = 'dmapError',
  },
  -- text used for diagnostic marks
  -- ⚠ the text must be one character long
  d_mark = {
    hint = '╸',
    info = '╸',
    warn = '╸',
    error = '╸',
  },
  -- ignore these diagnostic sources
  sources_ignored = {},
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
