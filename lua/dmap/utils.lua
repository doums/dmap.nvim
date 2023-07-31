-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local api = vim.api

local M = {}

function M.hl_exists(name)
  return not vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = name }))
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

function M.calculate_height(d_count, win_h, max_h)
  local h = d_count
  if h > win_h then
    h = win_h
  end
  if max_h and h > max_h then
    h = max_h
  end
  return h
end

function M.fill_map_buffer(buffer, height)
  local lines = {}
  for _ = 1, height do
    table.insert(lines, ' ')
  end
  api.nvim_set_option_value('modifiable', true, { buf = buffer })
  -- remove current lines
  api.nvim_buf_set_lines(buffer, 0, -1, false, {})
  -- set new lines
  api.nvim_buf_set_lines(buffer, 0, height, false, lines)
  api.nvim_set_option_value('modifiable', false, { buf = buffer })
end

return M
