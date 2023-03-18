local u = require("tabscope.utils")

-- Returns a table that tracks tab local buffers.
local function new(tracked_buffers)
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

  -- Tries to start tracks for current buffer
  m.try_to_add_the_buffer = function(id)
    if not m._tracked_buffers.is_tracked(id) then
      return
    end

    local current_tab = vim.api.nvim_get_current_tabpage()
    if not m._buffers_by_tab[current_tab] then
      m._buffers_by_tab[current_tab] = {}
    end
    m._buffers_by_tab[current_tab][id] = true
  end

  m._buffer_removed_handler = function(id)
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
    -- Gets sorted tab ids
    local sorted_tab_ids = {}
    for tab, _ in pairs(m._buffers_by_tab) do
      table.insert(sorted_tab_ids, tab)
    end
    table.sort(sorted_tab_ids)

    -- Gets tabs representation
    local representation = "Tab local buffers:\n"
    for _, tab in ipairs(sorted_tab_ids) do
      representation = representation .. "  tab " .. tostring(tab) .. ":\n"

      -- Gets sorted buffer ids
      local sorted_buffer_ids = {}
      for id, _ in pairs(m._buffers_by_tab[tab]) do
        table.insert(sorted_buffer_ids, id)
      end
      table.sort(sorted_buffer_ids)

      -- Gets buffer ids representation
      for _, id in ipairs(sorted_buffer_ids) do
        local buffer_representation = u.get_buffer_representation(id)
        representation =
          string.format("%s    %s\n", representation, buffer_representation)
      end
    end

    return representation
  end

  -- Sets event handlers
  u.on_event("BufAdd", function(event)
    m.try_to_add_the_buffer(event.buf)
  end)
  u.on_buffocused(function()
    local id = vim.api.nvim_get_current_buf()
    m.try_to_add_the_buffer(id)
  end)
  u.on_event("TabClosed", m._tab_closed_handler)
  m._tracked_buffers.on_buf_removed("tab-buffers", m._buffer_removed_handler)

  return m
end

return {
  new = new,
}
