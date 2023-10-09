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

  --- Removes buffers that isn't visible in any window for each tab.
  m.remove_not_visible_buffers = function()
    -- Removes not visible buffers
    local removed_buffers = {}
    for tab, tab_local_buffers in pairs(m._buffers_by_tab) do
      local tab_visible_buffers = {}
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local buffer = vim.api.nvim_win_get_buf(win)
        table.insert(tab_visible_buffers, buffer)
      end

      for buffer, _ in pairs(tab_local_buffers) do
        if not vim.tbl_contains(tab_visible_buffers, buffer) then
          removed_buffers[buffer] = true
          tab_local_buffers[buffer] = nil
        end
      end
    end

    -- Gets all orphan buffers
    local orphan_buffers = removed_buffers
    for _, tab_local_buffers in pairs(m._buffers_by_tab) do
      for buffer, _ in pairs(tab_local_buffers) do
        if orphan_buffers[buffer] then
          orphan_buffers[buffer] = nil
        end
      end
    end

    -- Notify that all orphan buffers must be removed.
    for buffer, _ in pairs(orphan_buffers) do
      m._tracked_buffers.remove(buffer)
    end
  end

  --- Removes buffer from current tab
  ---@param id number @ buffer to remove
  m.remove_buffer_for_current_tab = function(id)
    if id == nil or id == 0 then
      id = vim.api.nvim_get_current_buf()
    end

    local current_tab = vim.api.nvim_get_current_tabpage()

    -- Check if the buffer is managed by the plugin.
    if not m._buffers_by_tab[current_tab][id] then
      if vim.fn.buflisted(id) == 1 then
        vim.bo[id].buflisted = false
      end
      return
    end

    local show_another_buffer_for_window = function(tab, win)
      local another_buffer_to_show = -1
      for buffer, _ in pairs(m._buffers_by_tab[tab]) do
        if buffer ~= id then
          another_buffer_to_show = buffer
          break
        end
      end

      if another_buffer_to_show == -1 then
        another_buffer_to_show = vim.api.nvim_create_buf(true, true)
      end

      vim.api.nvim_win_set_buf(win, another_buffer_to_show)
    end

    -- Shows another buffer for windows in current tab with removed buffer.
    local wins = vim.api.nvim_tabpage_list_wins(current_tab)
    for _, win in ipairs(wins) do
      if id == vim.api.nvim_win_get_buf(win) then
        show_another_buffer_for_window(current_tab, win)
      end
    end

    m._buffers_by_tab[current_tab][id] = nil

    -- Checks if the buffer is orphan now.
    local orphan = true
    for _, buffers in pairs(m._buffers_by_tab) do
      for buffer, _ in pairs(buffers) do
        if id == buffer then
          orphan = false
        end
      end
    end

    if orphan then
      m._tracked_buffers.remove(id)
    else
      m._tracked_buffers.hide(id)
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
