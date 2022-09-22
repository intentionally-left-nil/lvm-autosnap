#! /bin/ash
# shellcheck shell=dash
# shellcheck disable=SC2086

set -u

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

config_set_defaults () {
  debug "func: config_set_defaults"
  MAX_SNAPSHOTS=5
  RESTORE_AFTER=2
  LOG_LEVEL=2
  CONFIGS=
  MODE=
}

load_config_from_env () {
  debug "func: load_config_from_env"
  # shellcheck source=/dev/null
  . /etc/lvm-autosnap/lvm-autosnap.env
}

load_config_from_cmdline () {
  debug "func: load_config_from_cmdline"
  local cmdline="$1"
  local arg
  local oldifs
  for arg in $cmdline; do
    get_cmdline_val "$arg"
    case $arg in
      (lvm-autosnap-max-snapshots=*) MAX_SNAPSHOTS="$get_cmdline_val_ret";;
      (lvm-autosnap-restore-after=*) RESTORE_AFTER="$get_cmdline_val_ret";;
      (lvm-autosnap-log-level=*) LOG_LEVEL="$get_cmdline_val_ret";;
      (lvm-autosnap-configs=*) CONFIGS="$get_cmdline_val_ret";;
      (lvm-autosnap-mode=*) MODE="$get_cmdline_val_ret";;
    esac
  done
}

get_cmdline_val () {
  debug "func: get_cmdline_val"
  local arg="$1"
  local oldifs="$IFS"
  IFS="="
  at_index "$arg" 1
  IFS="$oldifs"
  get_cmdline_val_ret="$at_index_ret"
}

config_columns () {
  debug "func: config_columns"
  config_columns_ret="vg_name,lv_name,snapshot_size"
}

config_field () {
  debug "func: config_field"
  local config="$1"
  local name="$2"
  config_columns
  field_by_header "$config" "$config_columns_ret" "$name" ","
  config_field_ret="$field_by_header_ret"
}

get_root_config () {
  local oldifs="$IFS"
  IFS="/"
  at_index "$CONFIGS" 0
  get_root_config_ret="$at_index_ret"
  IFS="$oldifs"
}

