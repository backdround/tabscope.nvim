local u = require("tabscope.utils")

-- Returns a table that manages tab switches.
local function new(buffer_manager)
  local m = {}
  m.buffer_manager = buffer_manager

  m.try_to_switch_tab = function()
    local previous_tab = m.previous_tab
    m.previous_tab = nil
    if previous_tab == nil then
      return
    end

    local previous_buffers = m.buffer_manager.tab_get_buffers(previous_tab)
    local current_buffers = m.buffer_manager.tab_get_buffers(0)

    m.buffer_manager.ignore_buf_hiding = true
    for buffer, _ in pairs(previous_buffers) do
      vim.bo[buffer].buflisted = false
    end
    m.buffer_manager.ignore_buf_hiding = false

    for buffer, _ in pairs(current_buffers) do
      vim.bo[buffer].buflisted = true
    end
  end

  u.set_improved_bufenter_autocmd(m.try_to_switch_tab)
  u.set_autocmd("TabLeave", function()
    m.previous_tab = vim.api.nvim_get_current_tabpage()
  end)

  return m
end

return {
  new = new,
}
