#! /usr/bin/env bats
function setup() {
  load 'test_helper/common-setup'
    common_setup
}

@test "config_set_defaults" {
  config_set_defaults
  assert_equal "$MAX_SNAPSHOTS" 5
  assert_equal "$RESTORE_AFTER" 2
  assert_equal "$LOG_LEVEL" 2
  assert_equal "$CONFIGS" ""
  assert_equal "$MODE" ""
  assert_equal "$REAL_IFS" $' \t\n'
}

@test "load_config_from_cmdline" {
  config_set_defaults
  load_config_from_cmdline "acpi=1 otherthing lvm-autosnap-max-snapshots=22 lvm-autosnap-restore-after=42 lvm-autosnap-log-level=1 lvm-autosnap-configs=myvg,root,20g/myvg,home,10g lvm-autosnap-mode=backup"
  assert_equal "$MAX_SNAPSHOTS" 22
  assert_equal "$RESTORE_AFTER" 42
  assert_equal "$LOG_LEVEL" 1
  assert_equal "$CONFIGS" "myvg,root,20g/myvg,home,10g"
  assert_equal "$MODE" "backup"
  assert_equal "$REAL_IFS" $' \t\n'
}

@test "config_field:empty configs" {
  config_field "" "lv_name"
  assert_equal "$CONFIG_FIELD_RET" ""
}

@test "config_field:vg_name" {
  config_field "myvg,mylv,10g" "vg_name"
  assert_equal "$CONFIG_FIELD_RET" "myvg"
}

@test "config_field:lv_name" {
  config_field "myvg,mylv,10g" "lv_name"
  assert_equal "$CONFIG_FIELD_RET" "mylv"
}

@test "config_field:snapshot_size" {
  config_field "myvg,mylv,10g" "snapshot_size"
  assert_equal "$CONFIG_FIELD_RET" "10g"
}

@test "config_field:invalid field" {
  run config_field "myvg,mylv,10g" "bad name"
  assert_failure
}

@test "config_field:missing field" {
  config_field "myvg,mylv" "snapshot_size"
  assert_equal "$CONFIG_FIELD_RET" ""
}

_set_valid_config () {
  config_set_defaults
  CONFIGS=myvg,root,10g
}

@test "validate_config:valid config" {
  _set_valid_config
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config:missing log level" {
  _set_valid_config
  LOG_LEVEL=
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$LOG_LEVEL" 2
}

@test "validate_config:bad log level" {
  _set_valid_config
  LOG_LEVEL=aeou
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$LOG_LEVEL" 2
}

@test "validate_config:negative log level" {
  _set_valid_config
  LOG_LEVEL="-1"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$LOG_LEVEL" 2
}

@test "validate_config:max_snapshots 0" {
  _set_valid_config
  MAX_SNAPSHOTS=0
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:bad max_snapshots" {
  _set_valid_config
  MAX_SNAPSHOTS=aeou
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:max_snapshots 3" {
  _set_valid_config
  MAX_SNAPSHOTS=3
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$MAX_SNAPSHOTS" 3
}

@test "validate_config:restore_after 0" {
  _set_valid_config
  RESTORE_AFTER=0
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$RESTORE_AFTER" 0
}

@test "validate_config:bad restore_after" {
  _set_valid_config
  RESTORE_AFTER=aeou
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:RESTORE_AFTER 3" {
  _set_valid_config
  RESTORE_AFTER=3
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$RESTORE_AFTER" 3
}

@test "validate_config:empty mode" {
  _set_valid_config
  MODE=
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$MODE" ""
}

@test "validate_config:mode backup" {
  _set_valid_config
  MODE=backup
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$MODE" "backup"
}

@test "validate_config:mode restore" {
  _set_valid_config
  MODE=restore
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
  assert_equal "$MODE" "restore"
}

@test "validate_config:bad mode" {
  _set_valid_config
  MODE=aoeu
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:no configs" {
  _set_valid_config
  CONFIGS=
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config: whitespace configs" {
  _set_valid_config
  CONFIGS=" "
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config: missing vg" {
  _set_valid_config
  CONFIGS=",mylv,10g"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config: vg with invalid character" {
  _set_valid_config
  CONFIGS="myvg^,mylv,10g"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config: vg with unusual but allowed characters" {
  _set_valid_config
  CONFIGS="myvg_abc.123+2-b,mylv,10g"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config: missing lv" {
  _set_valid_config
  CONFIGS="myvg,,10g"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config: lv with invalid character" {
  _set_valid_config
  CONFIGS="myvg,my lv,10g"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config: lv with unusual but allowed characters" {
  _set_valid_config
  CONFIGS="myvg,mylv_abc.123+2-b,10g"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config:missing size" {
  _set_valid_config
  CONFIGS="myvg,mylv"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:empty size" {
  _set_valid_config
  CONFIGS="myvg,mylv,"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:missing size number" {
  _set_valid_config
  CONFIGS="myvg,mylv,g"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:missing size suffix" {
  _set_valid_config
  CONFIGS="myvg,mylv,10"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:wrong size suffix" {
  _set_valid_config
  CONFIGS="myvg,mylv,10a"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" ""
}

@test "validate_config:5k" {
  _set_valid_config
  CONFIGS="myvg,mylv,5k"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}
@test "validate_config:03K" {
  _set_valid_config
  CONFIGS="myvg,mylv,03K"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config:123m" {
  _set_valid_config
  CONFIGS="myvg,mylv,123m"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config:1234M" {
  _set_valid_config
  CONFIGS="myvg,mylv,1234M"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config:12345g" {
  _set_valid_config
  CONFIGS="myvg,mylv,12345g"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config:123456G" {
  _set_valid_config
  CONFIGS="myvg,mylv,123456G"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config:1234567t" {
  _set_valid_config
  CONFIGS="myvg,mylv,1234567t"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}

@test "validate_config:12345678T" {
  _set_valid_config
  CONFIGS="myvg,mylv,12345678T"
  validate_config
  assert_equal "$VALIDATE_CONFIG_RET" "1"
}


