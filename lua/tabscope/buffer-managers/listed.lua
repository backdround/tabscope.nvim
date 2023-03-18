local u = require("tabscope.utils")

-- Returns a table that manages listed buffers.
local function new(tracked_buffers, tab_buffers)
  local m = {}
  m._tab_buffers = tab_buffers
  m._tracked_buffers = tracked_buffers

  m.update = function()
    local current_listed_buffers = m._tracked_buffers.get_listed_buffers()
    local current_tab_local_buffers = m._tab_buffers.get_current_tab_local_buffers()

    -- Delists buffers that aren't tab local.
    local buffers_to_delist = {}
    for _, buffer in ipairs(current_listed_buffers) do
      if not vim.tbl_contains(current_tab_local_buffers, buffer) then
        table.insert(buffers_to_delist, buffer)
      end
    end

    for _, buffer in ipairs(buffers_to_delist) do
      m._tracked_buffers.hide(buffer)
    end

    -- Lists buffers that tab local.
    local buffers_to_list = {}
    for _, buffer in ipairs(current_tab_local_buffers) do
      if not vim.tbl_contains(current_listed_buffers, buffer) then
        table.insert(buffers_to_list, buffer)
      end
    end

    for _, buffer in pairs(buffers_to_list) do
      m._tracked_buffers.show(buffer)
    end
  end

  m._try_to_update = function()
    if m._have_to_update then
      m.update()
      m._have_to_update = false
    end
  end

  u.on_buffocused(m._try_to_update)
  u.on_event("TabLeave", function()
    m._have_to_update = true
  end)

  return m
end

return {
  new = new,
}
