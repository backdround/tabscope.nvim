local u = require("tabscope.utils")

local function new()
  local b = {}
  b._buffers = {}
  b._on_buf_removed_callbacks = {}

  -- Track all current listed buffers
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].buflisted then
      b._buffers[id] = true
    end
  end

  b._is_showing = false
  b._add = function(id)
    if b._is_showing then
      return
    end

    if id == nil or id < 1 then
      return
    end

    if not vim.api.nvim_buf_is_valid(id) then
      return
    end

    b._buffers[id] = true
  end

  -- Sets event handlers
  u.on_event("BufAdd", function(event)
    b._add(event.buf)
  end)

  b._ignore_bufdelete = false
  u.on_event("BufDelete", function(event)
    if b._ignore_bufdelete then
      return
    end
    b.remove(event.buf)
  end)

  u.on_event("BufWipeout", function(event)
    b.remove(event.buf)
  end)

  b.remove = function(id)
    b._ignore_bufdelete = true
    vim.bo[id].buflisted = false
    b._ignore_bufdelete = false

    b._buffers[id] = nil

    for _, callback in pairs(b._on_buf_removed_callbacks) do
      callback(id)
    end
  end

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

  b.show = function(id)
    -- Buffer must be tracked
    if not b._buffers[id] then
      u.unexpected_behaviour()
      return
    end

    b._is_showing = true
    vim.bo[id].buflisted = true
    b._is_showing = false
  end

  b.get_listed_buffers = function()
    local list = {}
    for id, _ in pairs(b._buffers) do
      if vim.bo[id].buflisted then
        table.insert(list, id)
      end
    end
    return list
  end

  b.is_tracked = function(id)
    return b._buffers[id] == true
  end

  b.on_buf_removed = function(id, callback)
    b._on_buf_removed_callbacks[id] = callback
  end

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

  b.get_buffers = function()
    return vim.deepcopy(b._buffers)
  end

  return b
end

return {
  new = new
}
