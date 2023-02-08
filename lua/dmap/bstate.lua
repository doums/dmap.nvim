--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

---------
--- BState class
-- @classmod BState

--- Instance
-- @field config main config
-- @field buffer source buffer ID
-- @field dmaps list of the attached diagnostic map windows
-- @field diagnostics list of diagnostics for the source buffer
-- @table instance

local BState = {}

local DMap = require('dmap.dmap')
local utils = require('dmap.utils')

local api = vim.api

--- Create a new BState instance.
-- A BState represents a buffer to which is attached LSP client(s)
-- producing diagnostics. A BState contains all the windows
-- that render its buffer (reference windows). To each of these
-- windows is attached a diagnostic floating window (DMap).
-- @param config the main config
-- @int buffer the source buffer ID
-- @treturn BState the created instance
function BState:new(config, buffer)
  local instance = {
    config = config,
    buffer = buffer,
    dmaps = {}, -- indexed by ref window
    diagnostics = nil,
  }
  self.__index = self
  return setmetatable(instance, self)
end

--- Open the diagnostic map window for the given reference window.
-- @int window the ref window ID
function BState:open(window)
  if self.dmaps[window] then
    return
  end
  self.dmaps[window] = DMap:new(self.config, window)
  self.dmaps[window]:open()
end

--- Set and prepare the diagnostic list.
function BState:set_diagnostics()
  local config = self.config
  local lsp_diags =
    vim.diagnostic.get(self.buffer, { severity = config.severity })
  local raw_d = vim.tbl_map(function(d)
    d.row = utils.bufrow_to_dmaprow(
      d.lnum,
      api.nvim_buf_line_count(self.buffer),
      config.height
    )
    return d
  end, lsp_diags)

  -- filter by ignored sources
  if not vim.tbl_isempty(config.ignore_sources or {}) then
    raw_d = vim.tbl_filter(function(d)
      return not vim.tbl_contains(config.ignore_sources, d.source)
    end, raw_d)
  end

  local d_by_line = {} -- indexed by line number
  for _, d in ipairs(raw_d) do
    if not d_by_line[d.row] or d_by_line[d.row].severity > d.severity then
      d.mark = utils.get_mark(self.config, d.severity)
      d_by_line[d.row] = d
    end
  end

  self.diagnostics = d_by_line
end

--- Update the diagnostics.
-- This is a convenience function for using `set_diagnostics`
-- and `draw_diagnostics` in one call
function BState:update_diagnostics()
  self:set_diagnostics()

  for _, dmap in next, self.dmaps do
    dmap:draw_diagnostics(vim.deepcopy(self.diagnostics))
  end
end

--- Redraw dmap windows.
-- @int ?window the ref window ID
function BState:redraw(window)
  if window and self.dmaps[window] then
    self.dmaps[window]:redraw()
  else
    for _, dmap in next, self.dmaps do
      dmap:redraw()
    end
  end
end

--- Close the diagnostic map window attached to the given
-- reference window.
-- @int window the ref window ID
function BState:close(window)
  if self.dmaps[window] then
    self.dmaps[window]:kill()
    self.dmaps[window] = nil
  end
end

--- Close all diagnostic map windows for this buffer.
function BState:close_all()
  for win, dmap in next, self.dmaps do
    dmap:kill()
    self.dmaps[win] = nil
  end
end

return BState
