-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

---------
--- DMap class
-- @classmod DMap

--- Instance
-- @field config main config
-- @field ref reference to source buffer and source window
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
  local map_b = api.nvim_create_buf(false, true)
  api.nvim_set_option_value('filetype', 'dmap', { buf = map_b })

  local instance = {
    config = config,
    ref = { w = win, b = buf },
    map = { w = nil, b = map_b },
    diagnostics = {},
    ns_em_id = api.nvim_create_namespace(string.format('dmap_em_%d', win)),
  }
  self.__index = self
  return setmetatable(instance, self)
end

--- Open the diagnostic map window
function DMap:open()
  local win_cfg = vim.deepcopy(self.config.win_config)
  win_cfg.col = api.nvim_win_get_width(self.ref.w) - 1 - self.config.v_offset
  win_cfg.win = self.ref.w
  win_cfg.height = 1
  local win = api.nvim_open_win(self.map.b, false, win_cfg)
  api.nvim_win_set_hl_ns(win, self.config.ns_hl_id)
  vim.keymap.set({ 'n' }, '<LeftRelease>', function()
    on_click(self.map.b, win, self.diagnostics, self.ref.w)
  end, { buffer = self.map.b })
  self.map.w = win
end

--- Close the diagnostic map window
function DMap:close()
  if self.map.w and api.nvim_win_is_valid(self.map.w) then
    api.nvim_win_close(self.map.w, true)
  end
  self.map.w = nil
end

--- Set diagnostics
function DMap:set_diagnostics()
  local config = self.config
  local lsp_ds = vim.diagnostic.get(self.ref.b, { severity = config.severity })

  -- filter by ignored sources
  if not vim.tbl_isempty(config.ignore_sources or {}) then
    lsp_ds = vim.tbl_filter(function(d)
      return not vim.tbl_contains(config.ignore_sources, d.source)
    end, lsp_ds)
  end

  if vim.tbl_isempty(lsp_ds) then
    self.diagnostics = {}
    return
  end

  -- keep one diagnostic by line (diagnostic with high severity takes precedence)
  lsp_ds = vim.iter(lsp_ds):fold({}, function(acc, diagnostic)
    local row = diagnostic.lnum
    if not acc[row] or acc[row].severity > diagnostic.severity then
      acc[row] = diagnostic
    end
    return acc
  end)

  lsp_ds = vim
    .iter(lsp_ds)
    :map(function(_, d)
      return d
    end)
    :totable()

  -- sort diagnostics by severity
  table.sort(lsp_ds, function(a, b)
    return a.severity < b.severity
  end)

  self.diagnostics = lsp_ds
end

--- Draw diagnostic marks
function DMap:draw_diagnostics()
  if not self.map or not api.nvim_buf_is_valid(self.map.b) then
    self:kill()
    return
  end

  api.nvim_buf_clear_namespace(self.map.b, self.ns_em_id, 0, -1)

  local max_h = self.config.win_max_height
  local win_h = api.nvim_win_get_height(self.ref.w) - 1
  local slots = utils.calculate_height(#self.diagnostics, win_h, max_h)

  local d_it = vim.iter(self.diagnostics)
  for i, d in d_it:slice(1, slots):enumerate() do
    local mark = utils.get_mark(self.config, d.severity)
    local id = utils.set_extmark(self.ns_em_id, self.map.b, i - 1, mark)
    self.diagnostics[i].mark_id = id
  end
end

--- Redraw dmap window and diagnostics
function DMap:redraw()
  if not api.nvim_win_is_valid(self.ref.w) then
    self:kill()
    return
  end

  -- set diagnostics
  -- pcall(DMap.set_diagnostics, self)
  self:set_diagnostics()

  if vim.tbl_isempty(self.diagnostics) then
    self:close()
    return
  end

  if not self.map.w then
    self:open()
  end

  local max_h = self.config.win_max_height
  local win_h = api.nvim_win_get_height(self.ref.w) - 1
  local height = utils.calculate_height(#self.diagnostics, win_h, max_h)

  -- redraw the window
  api.nvim_win_set_config(self.map.w, {
    col = api.nvim_win_get_width(self.ref.w) - 1 - self.config.v_offset,
    row = 0,
    relative = 'win',
    win = self.ref.w,
    height = height,
  })
  api.nvim_win_set_hl_ns(self.map.w, self.config.ns_hl_id)
  utils.fill_map_buffer(self.map.b, height)

  -- redraw diagnostic marks
  -- pcall(DMap.draw_diagnostics, self)
  self:draw_diagnostics()
end

--- Kill this instance
function DMap:kill()
  if self.map then
    self:close()
    if api.nvim_buf_is_valid(self.map.b) then
      api.nvim_buf_delete(self.map.b, { force = true })
    end
  end
  self.config = nil
  self.ref = nil
  self.map = nil
  self.diagnostics = {}
  self.ns_em_id = nil
end

return DMap
