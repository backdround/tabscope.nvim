local u = require("tabscope.utils")

--- Creates new Tracked_buffer_manager.
---@return Tracked_buffer_manager
local function new()
  --- It tracks all the buffers that user want to use like a tab local buffers.
  --- It doesn't create or delete any buffers on its own, but tracks them
  --- and controls their buflisted options.
  ---@class Tracked_buffer_manager
  ---@field _buffers table<number, true> @ tracked buffer ids
  ---@field _on_buf_removed_callbacks table<any, function> @ callback that called when buffer is deleted
  ---@field _ignore_bufadd boolean @ wether the BufAdd event should be ignored
  ---@field _ignore_bufdelete boolean @ wether the BufDelete event should be ignored
  local b = {}

  b._buffers = {}
  b._on_buf_removed_callbacks = {}
  b._ignore_bufadd = false
  b._ignore_bufdelete = false

  -- Starts to track all current listed buffers.
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].buflisted then
      b._buffers[id] = true
    end
  end

  --- Handles BufAdd event
  b._add = function(id)
    if id == nil or id < 1 then
      return
    end

    if not vim.api.nvim_buf_is_valid(id) then
      return
    end

    b._buffers[id] = true
  end

  -- Sets event handlers.
  u.on_event("BufAdd", function(event)
    if b._ignore_bufadd then
      return
    end

    b._add(event.buf)
  end)

  u.on_event("BufDelete", function(event)
    if b._ignore_bufdelete then
      return
    end
    b.remove(event.buf)
  end)

  u.on_event("BufWipeout", function(event)
    b.remove(event.buf)
  end)

  --- Removes buffer from tracked buffers and delists it.
  ---@param id number buffer id
  b.remove = function(id)
    if not b._buffers[id] then
      return
    end

    b._ignore_bufdelete = true
    vim.bo[id].buflisted = false
    b._ignore_bufdelete = false

    b._buffers[id] = nil

    for _, callback in pairs(b._on_buf_removed_callbacks) do
      callback(id)
    end
  end

  --- Hides buffer.
  ---@param id number buffer id
  b.hide = function(id)
    -- Buffer must be tracked
    if not b._buffers[id] then
      u.unexpected_behaviour()
      return
    end

    b._ignore_bufdelete = true
    vim.bo[id].buflisted = false
    b._ignore_bufdelete = false
  end

  --- Shows buffer.
  ---@param id number buffer id
  b.show = function(id)
    -- Buffer must be tracked
    if not b._buffers[id] then
      u.unexpected_behaviour()
      return
    end

    b._ignore_bufadd = true
    vim.bo[id].buflisted = true
    b._ignore_bufadd = false
  end

  --- Returns listed buffres at the moment.
  ---@return number[] listed buffer ids
  b.get_listed_buffers = function()
    local list = {}
    for id, _ in pairs(b._buffers) do
      if vim.bo[id].buflisted then
        table.insert(list, id)
      end
    end
    return list
  end

  --- Returns wether the buffer id is tracked or not.
  ---@param id number buffer id
  ---@return boolean is it tracked
  b.is_tracked = function(id)
    return b._buffers[id] == true
  end

  --- Registers callback that is called when any buffer is removed.
  ---@param id any callback id that is used for replacement
  ---@param callback fun(id:number)
  b.on_buf_removed = function(id, callback)
    b._on_buf_removed_callbacks[id] = callback
  end

  --- Removes all buffers that isn't visible in any window.
  b.remove_not_visible_buffers = function()
    local visible_buffers = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local id = vim.api.nvim_win_get_buf(win)
        table.insert(visible_buffers, id)
      end
    end

    local buffers_to_remove = {}
    for id, _ in pairs(b._buffers) do
      if not vim.tbl_contains(visible_buffers, id) then
        table.insert(buffers_to_remove, id)
      end
    end

    for _, id in ipairs(buffers_to_remove) do
      b.remove(id)
    end
  end

  --- Returns current tracked ids.
  ---@return table<number, true> table with tracked buffer ids
  b.get_buffers = function()
    return vim.deepcopy(b._buffers)
  end

  return b
end

return {
  new = new
}
