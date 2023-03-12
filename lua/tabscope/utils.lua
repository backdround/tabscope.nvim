local M = {}

-- Creates auto command
M.set_autocmd = function(event, callback)
  if not M._group then
    M._group = vim.api.nvim_create_augroup("TabScopeNvim", {})
  end

  vim.api.nvim_create_autocmd(event, {
    group = M._group,
    callback = callback,
  })
end

return M
