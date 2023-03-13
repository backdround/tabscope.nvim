local M = {}

M.setup = function(_)
  local tab_buffer_manager = require("tabscope.tab-buffer-manager").new()
  M.listed_buffer_manager =
    require("tabscope.listed-buffer-manager").new(tab_buffer_manager)
end

return M
