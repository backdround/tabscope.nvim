local M = {}
local helpers = require("tests.test-helpers")

M.two_tabs_with_two_buffers_for_each_tab = function()
  require("tabscope").setup()

  -- Creates first tab with two buffers
  helpers.create_buffers({ "first", "second" })
  helpers.assert_listed_buffers({ "first", "second" })

  -- Creates second tab with two buffers
  helpers.new_tab_with_buffer("third")
  helpers.create_buffers({ "fourth" })
  helpers.assert_listed_buffers({ "third", "fourth" })

  -- Checks first tab
  vim.cmd("tabprevious")
  helpers.assert_listed_buffers({ "first", "second" })

  -- Checks second tab
  vim.cmd("tabnext")
  helpers.assert_listed_buffers({ "third", "fourth" })
end

M.not_a_mutual_buffer_deleted = function()
  require("tabscope").setup()

  -- Creates first tab with two buffers
  helpers.create_buffers({ "first", "second" })

  -- Creates second tab with two not mutual buffers.
  helpers.new_tab_with_buffer("third")
  helpers.open_buffer("fourth")

  -- Deletes third buffer
  vim.cmd("bdelete third")
  vim.wait(10)

  -- Checks first tab
  helpers.tabprevious()
  helpers.assert_listed_buffers({ "first", "second" })

  -- Checks second tab
  helpers.tabnext()
  helpers.assert_listed_buffers({ "fourth" })
end

M.tab_close = function()
  require("tabscope").setup()

  -- Creates first tab with two buffers
  helpers.create_buffers({ "first", "second" })

  -- Creates second tab with two buffers.
  helpers.new_tab_with_buffer("third")
  helpers.open_buffer("fourth")

  -- Closes current tab
  vim.cmd("tabclose")

  -- Checks first tab
  helpers.assert_listed_buffers({ "first", "second" })
end

M.tab_sbuffer = function()
  require("tabscope").setup()

  -- Creates first tab with two buffers
  helpers.create_buffers({ "first", "second" })
  helpers.open_buffer("second")

  -- Creates second tab with second buffer
  vim.cmd("tab sb")
  vim.wait(10)
  helpers.assert_listed_buffers({ "second" })

  -- Checks first tab
  helpers.tabprevious()
  helpers.assert_listed_buffers({ "first", "second" })

  -- Checks second tab
  helpers.tabnext()
  helpers.assert_listed_buffers({ "second" })
end

M.use_only_visible_buffers_on_load = function()
  -- Creates three buffers
  helpers.create_buffers({ "first", "second", "third" })
  helpers.open_buffer("second")

  -- Creates second tab and open new buffer
  helpers.new_tab_with_buffer("fourth")

  -- Loads plugin and checks that only visible buffers will be used.
  require("tabscope").setup()
  vim.wait(10)

  -- Asserts that only visible buffers listed.
  helpers.assert_listed_buffers({ "fourth" })
  helpers.tabprevious()
  helpers.assert_listed_buffers({ "second" })
end

M.use_only_visible_buffers_on_SessionLoadPost = function()
  require("tabscope").setup()

  -- Emulate session loading

  -- Creates first tab
  helpers.create_buffers({ "first", "second", "third" })
  helpers.open_buffer("first")
  helpers.split("second")

  -- Creates second tab
  helpers.new_tab_with_buffer("fourth")
  helpers.create_buffers({ "fifth" })
  helpers.open_buffer("fourth")

  -- Triggers SessionLoadPost
  vim.cmd("doautoall SessionLoadPost")
  vim.wait(10)

  -- Asserts that only visible buffers listed.
  helpers.assert_listed_buffers({ "fourth" })
  helpers.tabprevious()
  helpers.assert_listed_buffers({ "first", "second" })
end

M.use_only_visible_buffers_on_SessionLoadPost_even_if_some_buffers_are_mutual = function(
)
  require("tabscope").setup()

  -- Emulate session loading

  -- Creates first tab
  helpers.create_buffers({ "first", "second", "third" })
  helpers.open_buffer("first")

  -- Creates second tab
  helpers.new_tab_with_buffer("fourth")
  helpers.open_buffer("second")
  helpers.split("third")

  -- Triggers SessionLoadPost
  vim.cmd("doautoall SessionLoadPost")
  vim.wait(10)

  -- Asserts that only visible buffers listed.
  helpers.assert_listed_buffers({ "second", "third" })
  helpers.tabprevious()
  helpers.assert_listed_buffers({ "first" })
end

M.remove_local_tab_buffer_with_mutual_appearance = function()
  local tabscope = require("tabscope")
  tabscope.setup()

  -- Creates first tab
  helpers.create_buffers({ "first", "second" })
  helpers.open_buffer("first")

  -- Creates second tab
  helpers.new_tab_with_buffer("third")
  helpers.split("second")

  -- Removes local second buffer
  local second_buffer = helpers.get_buffer_by_name("second")
  tabscope.remove_tab_buffer(second_buffer)

  -- Asserts that second buffer was deleted only for local tab
  helpers.assert_listed_buffers({ "third" })
  helpers.tabprevious()
  helpers.assert_listed_buffers({ "first", "second" })
end

M.remove_local_tab_buffer_with_last_appearance = function()
  local tabscope = require("tabscope")
  tabscope.setup()

  -- Creates first tab
  helpers.create_buffers({ "first", "second" })

  -- Creates second tab
  helpers.new_tab_with_buffer("third")
  helpers.split("fourth")

  -- Removes local fourth buffer
  local fourth_buffer = helpers.get_buffer_by_name("fourth")
  tabscope.remove_tab_buffer(fourth_buffer)

  -- Asserts that fourth buffer was deleted only for local tab
  helpers.assert_listed_buffers({ "third" })
  helpers.tabprevious()
  helpers.assert_listed_buffers({ "first", "second" })
end

M.remove_local_tab_buffer_that_was_last_for_tab = function()
  local tabscope = require("tabscope")
  tabscope.setup()

  -- Creates first tab
  helpers.create_buffers({ "first", "second" })

  -- Creates second tab
  helpers.new_tab_with_buffer("third")

  -- Removes local third buffer
  local third_buffer = helpers.get_buffer_by_name("third")
  tabscope.remove_tab_buffer(third_buffer)

  -- Asserts that third buffer was replaced by noname buffer
  helpers.assert_listed_buffers({ "" })
  helpers.tabprevious()
  helpers.assert_listed_buffers({ "first", "second" })
end

return M
