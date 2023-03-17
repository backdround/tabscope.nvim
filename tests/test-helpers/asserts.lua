local utils = require("tests.test-helpers.utils")

local M = {}

local function throw_error(template, ...)
  local error_message = string.format(template, unpack({ ... }))
  error(error_message, 3)
end

M.assert_listed_buffers = function(expected_names)
  local listed_buffer_names = utils.get_listed_buffer_names()

  -- Asserts names
  for _, name in ipairs(expected_names) do
    if not vim.tbl_contains(listed_buffer_names, name) then
      throw_error(
        '\n  buffer: "%s" doesn\'t contains in buffers: %s',
        name,
        vim.inspect(listed_buffer_names)
      )
    end
  end

  -- Asserts count
  if #listed_buffer_names ~= #expected_names then
    throw_error(
      "\n  real buffers: %s\n  but expected buffers: %s",
      vim.inspect(listed_buffer_names),
      vim.inspect(expected_names)
    )
  end
end

return M
