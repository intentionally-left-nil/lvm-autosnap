#! /bin/ash
# shellcheck shell=dash

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

config_set_defaults () {
  debug "func: config_set_defaults"
  MAX_SNAPSHOTS=5
  RESTORE_AFTER=2
  LOG_LEVEL=2
  CONFIGS=
  MODE=
  REAL_IFS="$IFS"
}

load_config_from_env () {
  debug "func: load_config_from_env"
  # shellcheck source=/dev/null
  . /etc/lvm-autosnap.env
}

load_config_from_cmdline () {
  debug "func: load_config_from_cmdline"
  local cmdline_15="$1"
  local arg_15
  local oldifs_15="$IFS"
  IFS="$REAL_IFS"
  for arg_15 in $cmdline_15; do
    get_cmdline_val "$arg_15"
    case $arg_15 in
      (lvm-autosnap-max-snapshots=*) MAX_SNAPSHOTS="$get_cmdline_val_ret";;
      (lvm-autosnap-restore-after=*) RESTORE_AFTER="$get_cmdline_val_ret";;
      (lvm-autosnap-log-level=*) LOG_LEVEL="$get_cmdline_val_ret";;
      (lvm-autosnap-configs=*) CONFIGS="$get_cmdline_val_ret";;
      (lvm-autosnap-mode=*) MODE="$get_cmdline_val_ret";;
    esac
  done
  IFS="$oldifs_15"
}

get_cmdline_val () {
  debug "func: get_cmdline_val"
  local arg_16="$1"
  local oldifs_16="$IFS"
  IFS="="
  at_index "$arg_16" 1
  IFS="$oldifs_16"
  get_cmdline_val_ret="$at_index_ret"
}

config_columns () {
  debug "func: config_columns"
  config_columns_ret="vg_name,lv_name,snapshot_size"
}

config_field () {
  debug "func: config_field"
  local config_17="$1"
  local name_17="$2"
  config_columns
  field_by_header "$config_17" "$config_columns_ret" "$name_17" ","
  config_field_ret="$field_by_header_ret"
}

get_root_config () {
  local oldifs_18="$IFS"
  IFS="/"
  at_index "$CONFIGS" 0
  get_root_config_ret="$at_index_ret"
  IFS="$oldifs_18"
}

validate_config () {
  debug "func: validate_config"
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

  local oldifs_19="$IFS"
  local config_19
  IFS="/"
  for config_19 in $CONFIGS ; do
    config_field "$config_19" "vg_name"
    local vg_19="$config_field_ret"
    # From man lvm: The valid characters for VG and LV names are: a-z A-Z 0-9 + _ . -
    if [ -z "$vg_19" ] ; then
      error "Invalid vg($vg_19) for $config_19";
      return
    fi
    case $vg_19 in
      (*[!0-9a-zA-Z+_.-]*|'') error "Invalid vg($vg_19) for $config_19"; return;;
    esac

    config_field "$config_19" "lv_name"
    local lv_19="$config_field_ret"
    # From man lvm: The valid characters for VG and LV names are: a-z A-Z 0-9 + _ . -
    if [ -z "$lv_19" ] ; then
      error "Invalid lv($lv_19) for $config_19";
      return
    fi
    case $lv_19 in
      (*[!0-9a-zA-Z+_.-]*|'') error "Invalid lv($lv_19) for $config_19"; return;;
    esac

    config_field "$config_19" "snapshot_size"
    local size_19="$config_field_ret"
    if [ -z "$size_19" ] ; then
      error "Invalid size($size_19) for $config_19";
      return
    fi
    case $size_19 in
      ([0-9][kKmMgGtT]);;
      ([0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      ([0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][kKmMgGtT]);;
      (*) error "Invalid size($size_19) for $config_19"; return;;
    esac
  done
  IFS="$oldifs_19"
  validate_config_ret=1
}
