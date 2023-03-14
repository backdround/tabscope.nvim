local u = require("tabscope.utils")

-- Returns a table that tracks tab local buffers.
local function new(tracked_buffers)
  local m = {}
  m._tracked_buffers = tracked_buffers
  m._buffers_by_tab = {}

  -- Tries to start tracks for current buffer
  m._buffer_focus_handler = function()
    local buffer = vim.api.nvim_get_current_buf()
    if not m._tracked_buffers.is_tracked(buffer) then
      return
    end

    local current_tab = vim.api.nvim_get_current_tabpage()
    if not m._buffers_by_tab[current_tab] then
      m._buffers_by_tab[current_tab] = {}
    end
    m._buffers_by_tab[current_tab][buffer] = true
  end

  m._buffer_untrack_handler = function(id)
    for _, buffers in pairs(m._buffers_by_tab) do
      buffers[id] = nil
    end
  end

  -- Stops tracking closed tabs
  m._tab_closed_handler = function()
    local current_tabs = vim.api.nvim_list_tabpages()
    local closed_tabs = {}
    for tab, _ in pairs(m._buffers_by_tab) do
      if not vim.tbl_contains(current_tabs, tab) then
        table.insert(closed_tabs, tab)
      end
    end

    -- Gets all buffers that belongs to living tabs
    local remaining_buffers = {}
    for tab, _ in pairs(m._buffers_by_tab) do
      if not vim.tbl_contains(closed_tabs, tab) then
        for buffer, _ in pairs(m._buffers_by_tab[tab]) do
          table.insert(remaining_buffers, buffer)
        end
      end
    end

    -- Remove all buffers that don't belong to living tabs
    for _, tab in ipairs(closed_tabs) do
      for buffer, _ in pairs(m._buffers_by_tab[tab]) do
        if not vim.tbl_contains(remaining_buffers, buffer) then
          m._tracked_buffers.remove(buffer)
        end
      end
    end

    for _, tab in ipairs(closed_tabs) do
      m._buffers_by_tab[tab] = nil
    end
  end

  -- Resets all internal data. Reacquires only visible buffers.
  m.reset = function()
    -- Reacquires visible buffers.
    local new_buffers_by_tab = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      new_buffers_by_tab[tab] = {}
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local buffer = vim.api.nvim_win_get_buf(win)
        if m._tracked_buffers.is_tracked(buffer) then
          new_buffers_by_tab[tab][buffer] = true
        end
      end
    end
    m._buffers_by_tab = new_buffers_by_tab
  end

  -- Returns a list of current tab local buffers
  m.get_current_tab_local_buffers = function()
    local tab = vim.api.nvim_get_current_tabpage()

    if m._buffers_by_tab[tab] == nil then
      return {}
    end

    local tab_local_buffers = {}
    for buffer, _ in pairs(m._buffers_by_tab[tab]) do
      table.insert(tab_local_buffers, buffer)
    end
    return tab_local_buffers
  end

  m.get_internal_representation = function()
    local representation = "Tab local buffers:\n"
    for tab, buffers in pairs(m._buffers_by_tab) do
      representation = representation .. "  tab " .. tostring(tab) .. ":\n"
      for buffer, _ in pairs(buffers) do
        local name = vim.api.nvim_buf_get_name(buffer)
        name = vim.fn.fnamemodify(name, ":t")
        representation =
          string.format("%s    %s %s\n", representation, buffer, name)
      end
    end
    return representation
  end

  -- Sets event handlers
  u.on_buffocused(m._buffer_focus_handler)
  u.on_event("TabClosed", m._tab_closed_handler)
  m._tracked_buffers.on_buf_untrack("tab-buffers", m._buffer_untrack_handler)

  return m
end

return {
  new = new,
}
