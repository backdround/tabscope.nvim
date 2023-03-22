local M = {}

M.get_listed_buffers = function()
  local listed_buffers = {}

  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].buflisted then
      table.insert(listed_buffers, id)
    end
  end

  return listed_buffers
end

M.get_listed_buffer_names = function()
  local listed_buffer_names = {}

  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].buflisted then
      local buffer_name = vim.api.nvim_buf_get_name(id)
      buffer_name = vim.fn.fnamemodify(buffer_name, ":t")
      table.insert(listed_buffer_names, buffer_name)
    end
  end

  return listed_buffer_names
end

M.get_buffer_by_name = function(search_name)
  for _, id in ipairs(M.get_listed_buffers()) do
    local name = vim.api.nvim_buf_get_name(id)
    name = vim.fn.fnamemodify(name, ":t")
    if name == search_name then
      return id
    end
  end

  error("There is no buffer with the given name")
end

return M
