local u = require("tabscope.utils")

--- Creates new Tab_local_buffer_manager.
---@return Tab_local_buffer_manager
local function new(tracked_buffers)
  --- It manages tab local buffers. It removes buffers that don't need anymore.
  ---@class Tab_local_buffer_manager
  ---@field _tracked_buffers Tracked_buffer_manager
  ---@field _buffers_by_tab table<number, table<number, true>> @ table of tabs that contains tables of buffers
  local m = {}

  m._tracked_buffers = tracked_buffers
  m._buffers_by_tab = {}

  -- Acquires only visible buffers.
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    m._buffers_by_tab[tab] = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buffer = vim.api.nvim_win_get_buf(win)
      if m._tracked_buffers.is_tracked(buffer) then
        m._buffers_by_tab[tab][buffer] = true
      end
    end
  end

  --- Tries to add the given buffer to tab local buffers.
  ---@param id number @ buffer id
  m._try_to_add_the_buffer = function(id)
    if not m._tracked_buffers.is_tracked(id) then
      return
    end

    local current_tab = vim.api.nvim_get_current_tabpage()
    if not m._buffers_by_tab[current_tab] then
      m._buffers_by_tab[current_tab] = {}
    end
    m._buffers_by_tab[current_tab][id] = true
  end

  --- Handles buffer deletion.
  ---@param id number
  m._buffer_removed_handler = function(id)
    for _, buffers in pairs(m._buffers_by_tab) do
      buffers[id] = nil
    end
  end

  -- Handles tab closing. It removes buffers that don't need anymore.
  m._tab_closed_handler = function()
    local current_tabs = vim.api.nvim_list_tabpages()
    local closed_tabs = {}
    for tab, _ in pairs(m._buffers_by_tab) do
      if not vim.tbl_contains(current_tabs, tab) then
        table.insert(closed_tabs, tab)
      end
    end

    -- Gets all buffers that belongs to living tabs.
    local remaining_buffers = {}
    for tab, _ in pairs(m._buffers_by_tab) do
      if not vim.tbl_contains(closed_tabs, tab) then
        for buffer, _ in pairs(m._buffers_by_tab[tab]) do
          table.insert(remaining_buffers, buffer)
        end
      end
    end

    -- Gets all buffers that don't belongs to any living tabs.
    local orphan_buffers = {}
    for _, tab in ipairs(closed_tabs) do
      for buffer, _ in pairs(m._buffers_by_tab[tab]) do
        if not vim.tbl_contains(remaining_buffers, buffer) then
          table.insert(orphan_buffers, buffer)
        end
      end
    end

    -- Remove all closed tabs.
    for _, tab in ipairs(closed_tabs) do
      m._buffers_by_tab[tab] = nil
    end

    -- Notify that all orphan buffers must be removed.
    for _, buffer in ipairs(orphan_buffers) do
      m._tracked_buffers.remove(buffer)
    end
  end

  --- Returns a list of current tab local buffers.
  ---@return number[] buffer ids
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

  --- Returns all tab local buffers (<tab, <buffer, true>>).
  --- Please use it only for log purpouse.
  ---@return table<number, table<number, true>>
  m.get_tab_buffers = function()
    return vim.deepcopy(m._buffers_by_tab)
  end

  -- Sets event handlers.
  u.on_event("BufAdd", function(event)
    m._try_to_add_the_buffer(event.buf)
  end)
  u.on_buffocused(function()
    local id = vim.api.nvim_get_current_buf()
    m._try_to_add_the_buffer(id)
  end)
  u.on_event("TabClosed", m._tab_closed_handler)
  m._tracked_buffers.on_buf_removed("tab-buffers", m._buffer_removed_handler)

  return m
end

return {
  new = new,
}
