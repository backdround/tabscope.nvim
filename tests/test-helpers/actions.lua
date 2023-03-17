local utils = require("tests.test-helpers.utils")

local M = {}

local remove_buffer_with_empty_name = function()
  local listed_buffers = utils.get_listed_buffers()
  for _, id in ipairs(listed_buffers) do
    local name = vim.api.nvim_buf_get_name(id)
    if name == "" then
      vim.api.nvim_buf_delete(id, {})
      return
    end
  end
end

-- Creates buffers with name from the given array
M.create_buffers = function(names)
  for _, name in ipairs(names) do
    -- Checks name
    if name == "" then
      error("please don't use empty buffer name")
    end

    -- Creates buffer
    local id = vim.api.nvim_create_buf(true, true)
    if id == 0 then
      error("unable to create buffer :c")
    end
    vim.api.nvim_buf_set_name(id, name)
  end

  remove_buffer_with_empty_name()
end

-- Opens new tab with the given buffer name
M.new_tab_with_buffer = function(buffer_name)
  if buffer_name == "" then
    error("please don't use empty buffer name")
  end

  vim.cmd("tabnew " .. buffer_name)
end

M.open_buffer = function(name)
  vim.cmd("edit " .. name)
end

M.split = function(name)
  if name then
    vim.cmd("sp " .. name)
  else
    vim.cmd("sp")
  end
  vim.wait(10)
end

-- Switches to next tab
M.tabnext = function()
  vim.cmd("tabnext")
  vim.wait(10)
end

-- Switches to previous tab
M.tabprevious = function()
  vim.cmd("tabprevious")
  vim.wait(10)
end

return M
