-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local api = vim.api

local BState = require('dmap.bstate')
local hl_exists = require('dmap.utils').hl_exists

local M = {}

local mt = {}
function mt:__index(win)
  for _, bs in next, self do
    if bs.dmaps[win] then
      return bs
    end
  end
end

--- Main state
-- A dictionary list of BState (buffer state) indexed by buffers
-- Each BState contains a dictionary list of DMap (diagnostic map
-- window), indexed by windows they are attached to
-- The metatable allows to index a BState by window, if it
-- contains a DMap attached to the given window, it will match
-- @table state
local state = setmetatable({}, mt)

local function init_hls(config)
  local ns_id = config.ns_hl_id

  local hl_map = {
    error = 'Error',
    warn = 'Warn',
    info = 'Info',
    hint = 'Hint',
  }

  for key, value in pairs(hl_map) do
    if not hl_exists(config.d_hl[key]) then
      api.nvim_set_hl(
        ns_id,
        config.d_hl[key],
        { link = string.format('DiagnosticSign%s', value) }
      )
    end
  end

  api.nvim_set_hl(
    ns_id,
    'NormalFloat',
    { fg = 'NONE', bg = 'NONE', ctermbg = 'NONE' }
  )
end

function M.init(config)
  local group_id = api.nvim_create_augroup('dmap', {})
  init_hls(config)

  api.nvim_create_autocmd({ 'WinResized' }, {
    group = group_id,
    callback = function()
      for _, win in pairs(vim.v.event.windows) do
        local bs = state[win]
        if bs then
          vim.defer_fn(function()
            bs:redraw()
          end, 10)
        end
      end
    end,
  })

  api.nvim_create_autocmd('LspAttach', {
    group = group_id,
    callback = function(args)
      local bufnr = args.buf
      local filetype = api.nvim_get_option_value('filetype', { buf = bufnr })
      if
        state[bufnr] or vim.tbl_contains(config.ignore_filetypes, filetype)
      then
        return
      else
        local bs = BState:new(config, bufnr)
        bs:open(api.nvim_get_current_win())
        bs:update_diagnostics()
        state[bufnr] = bs
      end

      api.nvim_create_autocmd({ 'WinEnter', 'WinClosed' }, {
        group = group_id,
        buffer = bufnr,
        callback = function()
          for _, bs in next, state do
            vim.defer_fn(function()
              bs:redraw()
            end, 10)
          end
        end,
      })

      api.nvim_create_autocmd('LspDetach', {
        group = group_id,
        buffer = bufnr,
        callback = function(a)
          if state[a.buf] then
            state[a.buf]:close_all()
            state[a.buf] = nil
          end
        end,
      })

      api.nvim_create_autocmd({ 'BufWinEnter' }, {
        group = group_id,
        buffer = bufnr,
        callback = function(a)
          if state[a.buf] then
            state[a.buf]:open(api.nvim_get_current_win())
            state[a.buf]:update_diagnostics()
          end
        end,
      })

      api.nvim_create_autocmd({ 'BufWinLeave' }, {
        group = group_id,
        buffer = bufnr,
        callback = function(a)
          if state[a.buf] then
            state[a.buf]:close_all()
          end
        end,
      })

      api.nvim_create_autocmd({ 'DiagnosticChanged' }, {
        group = group_id,
        buffer = bufnr,
        callback = function(a)
          if state[a.buf] then
            state[a.buf]:update_diagnostics()
          end
        end,
      })
    end,
  })
end

return M
