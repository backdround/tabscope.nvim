local u = require("tabscope.utils")
local rep = require("tabscope.representation")

local M = {}

M.get_internal_representation = function()
  local result = ""

  local tracked_buffers =
    rep.buffers("Tracked buffers", M.tracked_buffers.get_buffers(), "")
  result = result .. tracked_buffers .. "--\n"

  local tab_local_buffers =
    rep.tabs("Tab local buffers", M.tab_buffers.get_tab_buffers())
  result = result .. tab_local_buffers .. "--\n"

  result = result .. rep.visible_tabs() .. "--\n"
  result = result .. rep.listed_buffers() .. "--"
  return result
end

M.setup = function(_)
  M.tracked_buffers = require("tabscope.tracked-buffers").new()
  M.tab_buffers = require("tabscope.tab-buffers").new(M.tracked_buffers)
  M.listed_buffers =
    require("tabscope.listed-buffers").new(M.tracked_buffers, M.tab_buffers)

  local reset_plugin_state = function()
    M.tracked_buffers.remove_not_visible_buffers()
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
