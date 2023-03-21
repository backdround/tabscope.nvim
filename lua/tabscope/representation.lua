--- Module provides utility functions to represent buffers and tabs.
local M = {}

--- Returns buffer representation.
---@param id number @ buffer id.
---@return string
M.buffer = function(id)
  local name = vim.api.nvim_buf_get_name(id)
  name = vim.fn.fnamemodify(name, ":t")
  return tostring(id) .. " " .. name
end

--- Returns string representation of the given buffer array.
---@param title string @ buffer description
---@param buffers table<number, true> @ table of buffer ids
---@param indention string
---@return string
M.buffers = function(title, buffers, indention)
  -- Gets sorted buffer ids
  local sorted_buffer_ids = {}
  for id, _ in pairs(buffers) do
    table.insert(sorted_buffer_ids, id)
  end
  table.sort(sorted_buffer_ids)

  -- Gets reperesentation
  local representation = indention .. title .. ":\n"
  for _, id in ipairs(sorted_buffer_ids) do
    local buffer_representation = M.buffer(id)
    representation = string.format(
      "%s%s  %s\n",
      representation,
      indention,
      buffer_representation
    )
  end
  return representation
end

--- Returns string representation of the given tabs.
---@param title string @ tab description
---@param tabs_with_buffers table<number, table<number, true>> @ a table with tabs, that contain tables with buffers
---@return string
M.tabs = function(title, tabs_with_buffers)
  -- Gets sorted tab ids
  local sorted_tab_ids = {}
  for tab, _ in pairs(tabs_with_buffers) do
    table.insert(sorted_tab_ids, tab)
  end
  table.sort(sorted_tab_ids)

  -- Gets tabs representation
  local representation = title .. ":\n"
  for _, tab in ipairs(sorted_tab_ids) do
    local tab_buffers = tabs_with_buffers[tab]
    local tab_title = "tab " .. tostring(tab)
    representation = representation .. M.buffers(tab_title, tab_buffers, "  ")
  end

  return representation
end

--- Returns listed buffers representation.
---@return string
M.listed_buffers = function()
  local listed_buffers = {}
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].buflisted then
      listed_buffers[id] = true
    end
  end
  return M.buffers("Listed buffers", listed_buffers, "")
end

--- Returns visible tabs representation.
---@return string
M.visible_tabs = function()
  local tabs_with_buffers = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    tabs_with_buffers[tab] = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local id = vim.api.nvim_win_get_buf(win)
      tabs_with_buffers[tab][id] = true
    end
  end

  return M.tabs("Tab visible buffers", tabs_with_buffers)
end

return M
