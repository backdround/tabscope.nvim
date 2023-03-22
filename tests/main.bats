setup_file() {
  # Gets the project root
  current_directory="$(dirname "$BATS_TEST_FILENAME")"
  project_root="$(realpath  "$current_directory/../")"
  test -d "$project_root"

  # Makes temporary execution environment
  test_work_directory="$(mktemp --directory "/tmp/tabscope-test-XXXXXXXX")"
  export test_work_directory
  cd "$test_work_directory"

  mkdir lua
  ln -s "$project_root/lua/tabscope" ./lua/tabscope
  ln -s "$project_root/tests" ./lua/tests

  # Creates initial wrapper, that runs test.lua
  cat > ./launch.lua <<EOF
vim.opt.runtimepath:prepend("$test_work_directory")

-- Executes test file

local succeed, error_message = pcall(dofile, "./test.lua")

-- Checks result and exit
if succeed then
  vim.cmd(":cquit 0")
else
  vim.notify_once(error_message, vim.log.levels.ERROR)
  vim.cmd(":cquit 1")
end
EOF
}

teardown_file() {
  rm -rf "$test_work_directory"
}

run_case() {
  # Gets current test name with space replaced by _
  case_name="${BATS_TEST_NAME#test_}"

  # Creates test.
  cat > ./test.lua <<EOF
    local cases = require("tests.test-cases")
    cases.$case_name()
EOF

  # Runs the test.
  nvim --headless --clean -u ./launch.lua
}

# Each test case here invokes the case with the same name, but space
# replaced by '_', from test cases in lua.

@test "two tabs with two buffers for each tab" {
  run_case
}

@test "not a mutual buffer deleted" {
  run_case
}

@test "tab close" {
  run_case
}

@test "tab sbuffer" {
  run_case
}

@test "use only visible buffers on load" {
  run_case
}

@test "use only visible buffers on SessionLoadPost" {
  run_case
}

@test "use only visible buffers on SessionLoadPost even if some buffers are mutual" {
  run_case
}

@test "remove local tab buffer with mutual appearance" {
  run_case
}

@test "remove local tab buffer with last appearance" {
  run_case
}

@test "remove local tab buffer that was last for tab" {
  run_case
}
