local u = require("tabscope.utils")

local M = {}

M.get_internal_representation = function()
  local result = ""
  result = result .. M.tab_buffers.get_internal_representation() .. "--\n"
  result = result .. u.get_tabs_representation() .. "--\n"
  result = result .. u.get_listed_buffers_representation() .. "--\n"
  result = result .. M.tracked_buffers.get_internal_representation() .. "--\n"
  return result
end

M.setup = function(_)
  M.tracked_buffers = require("tabscope.tracked-buffers").new()
  M.tab_buffers = require("tabscope.tab-buffers").new(M.tracked_buffers)
  M.listed_buffers =
    require("tabscope.listed-buffers").new(M.tracked_buffers, M.tab_buffers)

  local reset_plugin_state = function()
    M.tab_buffers.reset()
    M.listed_buffers.update()
  end

  u.on_event("SessionLoadPost", reset_plugin_state)

  reset_plugin_state()

  vim.api.nvim_create_user_command("TabScopeDebug", function()
    local output = M.get_internal_representation()
    print(output)
  end, {})
end

return M
