local M = {}

M._get_augroup = function()
  if not M._augroup then
    M._augroup = vim.api.nvim_create_augroup("TabScopeNvim", {})
  end
  return M._augroup
end

-- Registers callback that triggers when event happend
M.on_event = function(event, callback)
  vim.api.nvim_create_autocmd(event, {
    group = M._get_augroup(),
    callback = callback,
  })
end

-- Registers callback that triggers when buffer focussed.
-- It's like bufEnter, but it also triggers when a buffer changes to
-- the same buffer, like :sbuffer or :tab sbuffer
M.on_buffocused = function(callback)
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

-- Function to call when something gone wrong
M.unexpected_behaviour = function()
  local message = debug.traceback("Something gone wrong. Please file an issue:")
  vim.notify_once(message, vim.log.levels.WARN)
end

return M
