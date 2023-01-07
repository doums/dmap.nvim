--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

---------
--- DMap class
-- @classmod DMap

--- Instance
-- @field config main config
-- @field window ID of the reference window
-- @field map buffer and window used to render the diagnostic map window `{b=number,w=number}`
-- @field ns_em_id namespace ID used to draw the extmarks
-- @table instance

local DMap = {}

local utils = require('dmap.utils')
local on_click = require('dmap.on_click').on_click

local api = vim.api

--- Create a new DMap instance.
-- A DMap instance contains a duo of a reference window and an 
-- attached diagnostic map window.
-- @tparam config config the main config
-- @int win the reference window ID
-- @treturn DMap the created instance
function DMap:new(config, win)
  local instance = {
    config = config,
    window = win,
    map = nil,
    diagnostics = nil,
    ns_em_id = api.nvim_create_namespace(string.format('dmap_em_%d', win)),
  }
  self.__index = self
  return setmetatable(instance, self)
end

--- Open the diagnostic map window.
function DMap:open()
  local win_cfg = vim.deepcopy(self.config.win_config)
  win_cfg.col = api.nvim_win_get_width(self.window) - 2
  win_cfg.win = self.window
  local buf, win = unpack(utils.open_float_win(win_cfg))
  api.nvim_win_set_option(win, 'winblend', 100)
  api.nvim_win_set_hl_ns(win, self.config.ns_hl_id)
  vim.keymap.set({ 'n' }, '<LeftRelease>', function()
    on_click(buf, win, self.diagnostics, self.window)
  end, { buffer = buf })
  self.map = { b = buf, w = win }
end

--- Show the diagnostic list in the map window.
function DMap:draw_diagnostics(diagnostics)
  self.diagnostics = diagnostics
  api.nvim_buf_clear_namespace(self.map.b, self.ns_em_id, 0, -1)
  for row, d in pairs(diagnostics) do
    local id = utils.set_extmark(
      self.ns_em_id,
      self.map.b,
      row,
      d.severity,
      self.config.d_hl
    )
    self.diagnostics[row].mark_id = id
  end
end

--- Update the diagnostic list.
-- This is a convenience function for using `update_diagnostics`
-- and `set_diagnostics` in one call
function DMap:update_diagnostics()
  self:set_diagnostics()

  if self.map then
    self:draw_diagnostics()
  end
end

--- Redraw dmap window.
function DMap:redraw()
  api.nvim_win_set_config(self.map.w, {
    col = api.nvim_win_get_width(self.window) - 2,
    row = 1,
    relative = 'win',
    win = self.window,
  })
  api.nvim_win_set_hl_ns(self.map.w, self.config.ns_hl_id)
end

--- Kill this instance.
function DMap:kill()
  local win = self.map.w
  if api.nvim_win_is_valid(win) then
    api.nvim_win_close(win, true)
  end
  self.map = nil
  self.config = nil
  self.window = nil
  self.diagnostics = nil
  self.ns_em_id = nil
end

return DMap
