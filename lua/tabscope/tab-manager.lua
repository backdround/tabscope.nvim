local u = require("tabscope.utils")

-- Returns a table that manages tab switches.
local function new(buffer_manager)
  local m = {}
  m.buffer_manager = buffer_manager
  m.have_to_perform_tab_switch = false

  m.try_to_switch_tab = function()
    if not m.have_to_perform_tab_switch then
      return
    end
    m.have_to_perform_tab_switch = false

    local current_listed_buffers = u.get_listed_buffers()
    local new_tab_listed_buffers = m.buffer_manager.tab_get_buffers(0)

    -- Delists buffers that aren't tab local.
    local buffers_to_delist = {}
    for _, buffer in ipairs(current_listed_buffers) do
      if not vim.tbl_contains(new_tab_listed_buffers, buffer) then
        table.insert(buffers_to_delist, buffer)
      end
    end

    m.buffer_manager.ignore_buf_hiding = true
    for _, buffer in ipairs(buffers_to_delist) do
      vim.bo[buffer].buflisted = false
    end
    m.buffer_manager.ignore_buf_hiding = false

    -- Lists buffers that tab local.
    local buffers_to_list = {}
    for _, buffer in ipairs(new_tab_listed_buffers) do
      if not vim.tbl_contains(current_listed_buffers, buffer) then
        table.insert(buffers_to_list, buffer)
      end
    end

    for _, buffer in pairs(buffers_to_list) do
      vim.bo[buffer].buflisted = true
    end
  end

  u.set_improved_bufenter_autocmd(m.try_to_switch_tab)
  u.set_autocmd("TabLeave", function()
    m.have_to_perform_tab_switch = true
  end)

  return m
end

return {
  new = new,
}
