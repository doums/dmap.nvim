## dmap.nvim

One click goto LSP diagnostics

![dmap.nvim](https://github.com/doums/dmap.nvim/blob/main/public/dmap.gif "dmap.nvim in action")

### Install

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
