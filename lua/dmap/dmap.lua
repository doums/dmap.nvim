-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

---------
--- DMap class
-- @classmod DMap

--- Instance
-- @field config main config
-- @field window ID of the reference window
-- @field buffer source buffer ID
-- @field map buffer and window used to render the diagnostic map window `{b=number,w=number}`
-- @field diagnostics list of diagnostics for the source buffer
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
function DMap:new(config, win, buf)
  local instance = {
    config = config,
    window = win,
    buffer = buf,
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
  local win_h = api.nvim_win_get_height(self.window) - 1
  win_cfg.col = api.nvim_win_get_width(self.window) - 1 - self.config.v_offset
  win_cfg.win = self.window
  win_cfg.height = win_h
  local buf, win = unpack(utils.open_float_win(win_cfg))
  api.nvim_set_option_value('winblend', 100, { win = win })
  api.nvim_win_set_hl_ns(win, self.config.ns_hl_id)
  vim.keymap.set({ 'n' }, '<LeftRelease>', function()
    on_click(buf, win, self.diagnostics, self.window)
  end, { buffer = buf })
  self.map = { b = buf, w = win }
end

--- Set diagnostics, calculating their corresponding line number
-- in the dmap window.
function DMap:set_diagnostics()
  local config = self.config
  local ref_h = api.nvim_win_get_height(self.window) - 1
  local buf_lines = api.nvim_buf_line_count(self.buffer)
  local height = ref_h < buf_lines and ref_h or buf_lines
  local lsp_diags =
    vim.diagnostic.get(self.buffer, { severity = config.severity })
  local raw_d = vim.tbl_map(function(d)
    d.row = utils.bufrow_to_dmaprow(d.lnum, buf_lines, height)
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

--- Draw diagnostic marks
function DMap:draw_diagnostics()
  if not self.map or not api.nvim_buf_is_valid(self.map.b) then
    self:kill()
    return
  end

  api.nvim_buf_clear_namespace(self.map.b, self.ns_em_id, 0, -1)
  for row, d in pairs(self.diagnostics) do
    local id = utils.set_extmark(self.ns_em_id, self.map.b, row, d.mark)
    self.diagnostics[row].mark_id = id
  end
end

--- Update the diagnostics.
-- This is a convenience function for using `set_diagnostics`
-- and `draw_diagnostics` in one call
function DMap:flush()
  pcall(DMap.set_diagnostics, self)
  pcall(DMap.draw_diagnostics, self)
end

--- Redraw dmap window
function DMap:redraw()
  if
    not self.map
    or not api.nvim_win_is_valid(self.map.w)
    or not api.nvim_win_is_valid(self.window)
  then
    self:kill()
    return
  end

  -- clear diagnostics
  api.nvim_buf_clear_namespace(self.map.b, self.ns_em_id, 0, -1)

  -- redraw the window
  local ref_h = api.nvim_win_get_height(self.window) - 1
  local height = ref_h > 1 and ref_h or 1
  api.nvim_win_set_config(self.map.w, {
    col = api.nvim_win_get_width(self.window) - 1 - self.config.v_offset,
    row = 0,
    relative = 'win',
    win = self.window,
    height = height,
  })
  api.nvim_win_set_hl_ns(self.map.w, self.config.ns_hl_id)

  -- update diagnostics
  self:flush()
end

--- Kill this instance
function DMap:kill()
  if self.map then
    local win = self.map.w
    if api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end
  self.map = nil
  self.config = nil
  self.window = nil
  self.diagnostics = nil
  self.ns_em_id = nil
end

return DMap
