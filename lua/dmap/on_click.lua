-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local M = {}

local api = vim.api

function M.on_click(buffer, _, diagnostics, win_ref)
  if not api.nvim_win_is_valid(win_ref) then
    local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))
    api.nvim_set_current_win(prev_win)
    return
  end

  local marks = vim.inspect_pos(buffer, nil, nil, { extmarks = 'all' })
  if vim.tbl_isempty(marks.extmarks) then
    api.nvim_set_current_win(win_ref)
    return
  end

  local diagnostic
  for _, d in pairs(diagnostics) do
    if d.mark_id == marks.extmarks[1].id then
      diagnostic = d
    end
  end

  api.nvim_set_current_win(win_ref)
  if diagnostic then
    api.nvim_win_set_cursor(win_ref, { diagnostic.lnum + 1, diagnostic.col })
  end
end

return M
