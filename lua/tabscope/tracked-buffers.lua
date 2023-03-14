local u = require("tabscope.utils")

local function new()
  local b = {}
  b._buffers = {}
  b._on_buf_untrack_callbacks = {}

  b._is_showing = false
  b._add = function(event)
    local id = event.buf
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

  b._is_hidding = false
  b._delete = function(event)
    local id = event.buf
    if b._is_hidding then
      return
    end

    b._buffers[id] = nil
    for _, callback in pairs(b._on_buf_untrack_callbacks) do
      callback(id)
    end
  end

  -- Track all current listed buffers
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].buflisted then
      b._buffers[id] = true
    end
  end

  -- Sets event handlers
  u.on_event("BufAdd", b._add)
  u.on_event("BufDelete", b._delete)

  b.hide = function(id)
    -- Buffer must be tracked
    if not b._buffers[id] then
      u.unexpected_behaviour()
      return
    end

    b._is_hidding = true
    vim.bo[id].buflisted = false
    b._is_hidding = false
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

  b.on_buf_untrack = function(id, callback)
    b._on_buf_untrack_callbacks[id] = callback
  end

  b.get_internal_representation = function()
    local representation = "Tracked buffers:\n"
    for id, _ in pairs(b._buffers) do
      representation = representation .. "  " .. tostring(id) .. "\n"
    end
    return representation
  end

  return b
end

return {
  new = new
}
