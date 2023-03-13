local u = require("tabscope.utils")

-- Returns a table that manages listed buffers.
local function new(tab_buffer_manager)
  local m = {}
  m._tab_buffer_manager = tab_buffer_manager

  m.update = function()
    local current_listed_buffers = u.get_listed_buffers()
    local new_tab_buffers =
      m._tab_buffer_manager.tab_get_current_local_buffers()

    -- Delists buffers that aren't tab local.
    local buffers_to_delist = {}
    for _, buffer in ipairs(current_listed_buffers) do
      if not vim.tbl_contains(new_tab_buffers, buffer) then
        table.insert(buffers_to_delist, buffer)
      end
    end

    m._tab_buffer_manager.ignore_buf_unlisting = true
    for _, buffer in ipairs(buffers_to_delist) do
      vim.bo[buffer].buflisted = false
    end
    m._tab_buffer_manager.ignore_buf_unlisting = false

    -- Lists buffers that tab local.
    local buffers_to_list = {}
    for _, buffer in ipairs(new_tab_buffers) do
      if not vim.tbl_contains(current_listed_buffers, buffer) then
        table.insert(buffers_to_list, buffer)
      end
    end

    for _, buffer in pairs(buffers_to_list) do
      vim.bo[buffer].buflisted = true
    end
  end

  m._try_to_update = function()
    if m._have_to_update then
      m.update()
      m._have_to_update = false
    end
  end

  u.set_improved_bufenter_autocmd(m._try_to_update)
  u.set_autocmd("TabLeave", function()
    m._have_to_update = true
  end)

  return m
end

return {
  new = new,
}
