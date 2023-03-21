--- Module contains handy functions
local M = {}

local function _get_augroup()
  if not M._augroup then
    M._augroup = vim.api.nvim_create_augroup("TabScopeNvim", {})
  end
  return M._augroup
end

--- Registers callback that triggers when event happened
---@param event string|string[] @ it's a vim event string
---@param callback function
M.on_event = function(event, callback)
  vim.api.nvim_create_autocmd(event, {
    group = _get_augroup(),
    callback = callback,
  })
end

--- Registers callback that triggers when buffer focussed.
--- It's like bufEnter, but it also triggers when a buffer changes to
--- the same buffer, like with :sbuffer or :tab sbuffer
---@param callback function
M.on_buffocused = function(callback)
  local triggered = false

  vim.api.nvim_create_autocmd("BufEnter", {
    group = _get_augroup(),
    callback = function()
      triggered = true
      callback()
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = _get_augroup(),
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


--- Function to call when something gone wrong.
M.unexpected_behaviour = function()
  local message = debug.traceback("Something gone wrong. Please file an issue:")
  vim.notify_once(message, vim.log.levels.WARN)
end

return M
