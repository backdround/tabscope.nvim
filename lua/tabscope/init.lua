local M = {}

M.setup = function(_)
  local tracked_buffers = require("tabscope.tracked-buffers").new()
  local tab_buffer_manager = require("tabscope.tab-buffer-manager").new(tracked_buffers)
  M.listed_buffer_manager =
    require("tabscope.listed-buffer-manager").new(tracked_buffers, tab_buffer_manager)

  local reset_plugin_state = function()
    tab_buffer_manager.reset()
    M.listed_buffer_manager.update()
  end

  local u = require("tabscope.utils")
  u.set_autocmd("SessionLoadPost", reset_plugin_state)

  reset_plugin_state()
end

return M
