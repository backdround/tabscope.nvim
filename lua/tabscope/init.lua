local M = {}

M.setup = function(_)
  local tracked_buffers = require("tabscope.tracked-buffers").new()
  local tab_buffers = require("tabscope.tab-buffers").new(tracked_buffers)
  M.listed_buffers =
    require("tabscope.listed-buffers").new(tracked_buffers, tab_buffers)

  local reset_plugin_state = function()
    tab_buffers.reset()
    M.listed_buffers.update()
  end

  local u = require("tabscope.utils")
  u.on_event("SessionLoadPost", reset_plugin_state)

  reset_plugin_state()
end

return M
