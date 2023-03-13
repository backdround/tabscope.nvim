local M = {}

M._get_augroup = function()
  if not M._augroup then
    M._augroup = vim.api.nvim_create_augroup("TabScopeNvim", {})
  end
  return M._augroup
end

-- Creates auto command
M.set_autocmd = function(event, callback)
  vim.api.nvim_create_autocmd(event, {
    group = M._get_augroup(),
    callback = callback,
  })
end

-- Creates auto command that triggered like bufEnter, but it triggers
-- if buffer changes to the same buffer (like :sbuffer / :tab sbuffer)
M.set_improved_bufenter_autocmd = function(callback)
  local triggered = false

  vim.api.nvim_create_autocmd("BufEnter", {
    group = M._get_augroup(),
    callback = function()
      triggered = true
      callback()
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = M._get_augroup(),
    callback = function()
      triggered = false
      vim.schedule(function()
        if triggered then
          return
        end
        triggered = true
        callback()
      end)
    end,
  })

end

M.get_listed_buffers = function()
  local listed_buffers = {}
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].buflisted then
      table.insert(listed_buffers, buffer)
    end
  end
  return listed_buffers
end

return M
