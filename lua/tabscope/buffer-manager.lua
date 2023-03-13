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

    local current_tab = vim.api.nvim_get_current_tabpage()
    if not m._buffers_by_tab[current_tab] then
      m._buffers_by_tab[current_tab] = {}
    end
    m._buffers_by_tab[current_tab][buffer] = true
  end

  m._try_to_untrack_abuf = function()
    local buffer = tonumber(vim.fn.expand("<abuf>"))
    if type(buffer) ~= "number" then
      return
    end

    for _, buffers in pairs(m._buffers_by_tab) do
      buffers[buffer] = nil
    end
  end

  m._tab_closed_event = function()
    local tab = tonumber(vim.fn.expand("<afile>"))
    if type(tab) ~= "number" then
      return
    end

    m._buffers_by_tab[tab] = nil
  end

  -- Returns a list of tab local buffers
  m.tab_get_buffers = function(tab)
    if not tab or tab < 1 then
      tab = vim.api.nvim_get_current_tabpage()
    end

    if m._buffers_by_tab[tab] == nil then
      return {}
    end

    local tab_local_buffers = {}
    for buffer, _ in pairs(m._buffers_by_tab[tab]) do
      table.insert(tab_local_buffers, buffer)
    end
    return tab_local_buffers
  end


  u.set_improved_bufenter_autocmd(m._try_to_track_current_buffer)

  m.ignore_buf_hiding = false
  u.set_autocmd("BufDelete", function()
    if not m.ignore_buf_hiding then
      m._try_to_untrack_abuf()
    end
  end)

  u.set_autocmd("TabClosed", m._tab_closed_event)

  return m
end

return {
  new = new,
}
