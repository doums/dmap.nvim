--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local M = {}

-- Default config
local _config = {
  -- diagnostics windows height (terminal column)
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
}

local win_config = {
  style = 'minimal',
  border = 'none',
  relative = 'win',
  row = 1,
  col = 0,
  width = 1,
  zindex = 20,
}

function M.init(config)
  _config = vim.tbl_deep_extend('force', _config, config or {})

  if _config.nvim_float_api then
    win_config =
      vim.tbl_deep_extend('force', win_config, _config.nvim_float_api)
  end
  win_config.height = _config.height
  _config.win_config = win_config
  -- namespace for diagnostic window highlights
  _config.ns_hl_id = vim.api.nvim_create_namespace('dmap_hl_win')
  return _config
end

function M.get_config()
  return _config
end

return M
