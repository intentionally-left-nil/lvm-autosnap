common_setup() {
  SCRIPT_PATH="$PWD"
  # shellcheck source=config.sh
  . "$SCRIPT_PATH/config.sh"

  # shellcheck source=util.sh
  . "$SCRIPT_PATH/util.sh"

  # shellcheck source=lvol.sh
  . "$SCRIPT_PATH/lvol.sh"

  # shellcheck source=cli.sh
  . "$SCRIPT_PATH/cli.sh"

  # shellcheck source=core.sh
  . "$SCRIPT_PATH/core.sh"

  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
}

assert_ifs() {
  local _expected=$' \t\n'
  assert_equal "$_expected" "$IFS"
}
