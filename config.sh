#! /bin/ash
# shellcheck shell=dash

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
  . /etc/lvm-autosnap.env
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

validate_config () {
  validate_config_ret=
  LOG_LEVEL="${LOG_LEVEL:-2}"
  is_number "$LOG_LEVEL"
  if [ -z "$is_number_ret" ] || [ "$LOG_LEVEL" -lt 0 ] || [ "$LOG_LEVEL" -gt 3 ] ; then
    LOG_LEVEL=2
  fi

  is_number "$MAX_SNAPSHOTS"
  if [ -z "$is_number_ret" ] || [ "$MAX_SNAPSHOTS" -le 0 ] ; then
    error "MAX_SNAPSHOTS($MAX_SNAPSHOTS) is invalid"
    return
  fi

  is_number "$RESTORE_AFTER"
  if [ -z "$is_number_ret" ] || [ "$RESTORE_AFTER" -lt 0 ] || [ "$RESTORE_AFTER" -gt 9 ] ; then
    error "RESTORE_AFTER($RESTORE_AFTER) is invalid"
    return
  fi

  if [ -n "$MODE" ] && [ "$MODE" != "backup" ] && [ "$MODE" != "restore" ] ; then 
    error "MODE($MODE) is invalid"
    return
  fi

  if [ -z "$CONFIGS" ] ; then
    error "Missing CONFIGS"
    return
  fi

  local oldifs="$IFS"
  IFS="/"
  for config in $CONFIGS ; do
    config_field "$config" "vg_name"
    local vg="$config_field_ret"
    # From man lvm: The valid characters for VG and LV names are: a-z A-Z 0-9 + _ . -
    if [ -z "$vg" ] ; then
      error "Invalid vg($vg) for $config";
      return
    fi
    case $vg in
      (*[!0-9a-zA-Z+_.-]*|'') error "Invalid vg($vg) for $config"; return;;
    esac

    config_field "$config" "lv_name"
    local lv="$config_field_ret"
    # From man lvm: The valid characters for VG and LV names are: a-z A-Z 0-9 + _ . -
    if [ -z "$lv" ] ; then
      error "Invalid lv($lv) for $config";
      return
    fi
    case $lv in
      (*[!0-9a-zA-Z+_.-]*|'') error "Invalid lv($lv) for $config"; return;;
    esac

    config_field "$config" "snapshot_size"
    local size="$config_field_ret"
    if [ -z "$size" ] ; then
      error "Invalid size($size) for $config";
      return
    fi
    case $size in
      ([0-9][kKmMgGtT]);;
      ([0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      (*) error "Invalid size($size) for $config"; return;;
    esac
  done
  IFS="$oldifs"
  validate_config_ret=1
}
