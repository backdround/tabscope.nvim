local M = {}

M.setup = function(_)
  local buffer_manager = require("tabscope.buffer-manager").new()
  M.tab_manager = require("tabscope.tab-manager").new(buffer_manager)
end

return M
