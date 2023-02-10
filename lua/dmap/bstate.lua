-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
  self.dmaps[window] = DMap:new(self.config, window, self.buffer)
  self.dmaps[window]:open()
end

--- Update diagnostics.
-- Update and redraw diagnostic marks for each window rendering
-- the source buffer
function BState:update_diagnostics()
  for _, dmap in next, self.dmaps do
    dmap:flush()
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
