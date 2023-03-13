local u = require("tabscope.utils")

-- Returns a table that stores and tracks tab local buffers.
local function new()
  local m = {}
  m._buffers_by_tab = {}

  m._is_buffer_trackable = function(id)
    if id == nil or id < 1 then
      return false
    end

    if not vim.api.nvim_buf_is_valid(id) then
      return false
    end

    for _, buffers in pairs(m._buffers_by_tab) do
      for buffer, _ in pairs(buffers) do
        if buffer == id then
          return true
        end
      end
    end

    local listed = vim.bo[id].buflisted
    return listed
  end

  m._try_to_track_current_buffer = function()
    local buffer = vim.api.nvim_get_current_buf()
    if not m._is_buffer_trackable(buffer) then
      return
    end

    local current_tab_buffers = m.tab_get_buffers(0)
    current_tab_buffers[buffer] = true
  end

  m._try_to_untrack_abuf = function()
    local buffer = tonumber(vim.fn.expand("<abuf>"))
    if type(buffer) ~= "number" then
      return
    end

    for _, tab_buffers in ipairs(m._buffers_by_tab) do
      tab_buffers[buffer] = nil
    end
  end

  m.tab_get_buffers = function(tab)
    if not tab or tab < 1 then
      tab = vim.api.nvim_get_current_tabpage()
    end

    if m._buffers_by_tab[tab] == nil then
      m._buffers_by_tab[tab] = {}
    end

    return m._buffers_by_tab[tab]
  end


  u.set_improved_bufenter_autocmd(m._try_to_track_current_buffer)

  m.ignore_buf_hiding = false
  u.set_autocmd("BufDelete", function()
    if not m.ignore_buf_hiding then
      m._try_to_untrack_abuf()
    end
  end)

  return m
end

return {
  new = new,
}
