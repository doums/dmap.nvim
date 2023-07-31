-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local M = {}

-- Default config
local _config = {
  -- highlight groups used for diagnostic marks
  -- by default link to corresponding `DiagnosticSign*` groups
  d_hl = {
    hint = 'dmapHint',
    info = 'dmapInfo',
    warn = 'dmapWarn',
    error = 'dmapError',
  },
  -- highlight group used for the diagnostic map window
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
  -- max height of the diagnostic map window
  -- if not set defaults to the height of the reference window
  -- must be positive
  win_max_height = nil,
  -- ignore these diagnostic sources
  ignore_sources = {},
  -- ignore these filetypes buffer
  ignore_filetypes = { 'NvimTree' },
  -- severity option passed to `vim.diagnostic.get()` (`:h diagnostic-severity`)
  severity = nil,
  -- vertical offset (in character cells) of the diagnostic window
  -- must be positive
  v_offset = 0,
  -- override arguments passed to `nvim_open_win` (see `:h nvim_open_win`)
  -- ⚠ can potentially break the plugin, use at your own risk
  nvim_float_api = nil,
}

local win_config = {
  style = 'minimal',
  border = 'none',
  relative = 'win',
  row = 0,
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
