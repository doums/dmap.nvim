-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local api = vim.api

local M = {}

function M.hl(name, fg, bg, style, sp)
  local hl_map = { fg = fg, bg = bg, sp = sp }
  if type(style) == 'string' then
    hl_map[style] = 1
  elseif type(style) == 'table' then
    for _, v in ipairs(style) do
      hl_map[v] = 1
    end
  end
  api.nvim_set_hl(0, name, hl_map)
end

function M.hl_exists(name)
  local status = pcall(api.nvim_get_hl_by_name, name, {})
  return status
end

function M.get_mark(config, severity)
  local hl_map = {
    [vim.diagnostic.severity.HINT] = { config.d_mark.hint, config.d_hl.hint },
    [vim.diagnostic.severity.INFO] = { config.d_mark.info, config.d_hl.info },
    [vim.diagnostic.severity.WARN] = { config.d_mark.warn, config.d_hl.warn },
    [vim.diagnostic.severity.ERROR] = { config.d_mark.error, config.d_hl.error },
  }
  return hl_map[severity]
end

function M.set_extmark(ns_id, buffer, row, mark)
  local id = api.nvim_buf_set_extmark(buffer, ns_id, row, 0, {
    virt_text = { mark },
    virt_text_pos = 'overlay',
    hl_mode = 'combine',
  })
  return id
end

--- Convert a diagnostic line number to DMap window location
-- Convert a diagnostic line number relative to the buffer lines
-- to the matching DMap window location
-- @int row buffer line number of the diagnostic
-- @int lines buffer lines count
-- @int dmap_lines lines count of the DMap window
-- @treturn corresponding line number in the DMap window
function M.bufrow_to_dmaprow(row, lines, dmap_lines)
  local pos
  if row == 0 or lines == 0 then
    pos = 0
  elseif lines == 1 then
    pos = 0
  elseif row == lines - 1 then
    pos = dmap_lines - 1
  else
    pos = math.floor((row * dmap_lines) / lines)
  end
  return pos > 0 and pos or 0
end

function M.open_float_win(config)
  local buffer = api.nvim_create_buf(false, true)
  local window = api.nvim_open_win(buffer, false, config)
  local lines = {}
  for _ = 1, config.height do
    table.insert(lines, ' ')
  end
  api.nvim_buf_set_lines(buffer, 0, config.height, false, lines)
  api.nvim_buf_set_option(buffer, 'modifiable', false)
  api.nvim_buf_set_option(buffer, 'filetype', 'dmap')
  return { buffer, window }
end

return M
