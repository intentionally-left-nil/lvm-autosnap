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
      (lvm-autosnap-max-snapshots=*) MAX_SNAPSHOTS="$GET_CMDLINE_VAL_RET";;
      (lvm-autosnap-restore-after=*) RESTORE_AFTER="$GET_CMDLINE_VAL_RET";;
      (lvm-autosnap-log-level=*) LOG_LEVEL="$GET_CMDLINE_VAL_RET";;
      (lvm-autosnap-configs=*) CONFIGS="$GET_CMDLINE_VAL_RET";;
      (lvm-autosnap-mode=*) MODE="$GET_CMDLINE_VAL_RET";;
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
  GET_CMDLINE_VAL_RET="$AT_INDEX_RET"
}

config_columns () {
  debug "func: config_columns"
  CONFIG_COLUMNS_RET="vg_name,lv_name,snapshot_size"
}

config_field () {
  debug "func: config_field"
  local config_17="$1"
  local name_17="$2"
  config_columns
  field_by_header "$config_17" "$CONFIG_COLUMNS_RET" "$name_17" ","
  CONFIG_FIELD_RET="$FIELD_BY_HEADER_RET"
}

validate_config () {
  debug "func: validate_config"
  VALIDATE_CONFIG_RET=
  LOG_LEVEL="${LOG_LEVEL:-2}"
  is_number "$LOG_LEVEL"
  if [ -z "$IS_NUMBER_RET" ] || [ "$LOG_LEVEL" -lt 0 ] || [ "$LOG_LEVEL" -gt 3 ] ; then
    LOG_LEVEL=2
  fi

  is_number "$MAX_SNAPSHOTS"
  if [ -z "$IS_NUMBER_RET" ] || [ "$MAX_SNAPSHOTS" -le 0 ] ; then
    error "MAX_SNAPSHOTS($MAX_SNAPSHOTS) is invalid"
    return
  fi

  is_number "$RESTORE_AFTER"
  if [ -z "$IS_NUMBER_RET" ] || [ "$RESTORE_AFTER" -lt 0 ] || [ "$RESTORE_AFTER" -gt 9 ] ; then
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
    local vg_19="$CONFIG_FIELD_RET"
    # From man lvm: The valid characters for VG and LV names are: a-z A-Z 0-9 + _ . -
    if [ -z "$vg_19" ] ; then
      error "Invalid vg($vg_19) for $config_19";
      return
    fi
    case $vg_19 in
      (*[!0-9a-zA-Z+_.-]*|'') error "Invalid vg($vg_19) for $config_19"; return;;
    esac

    config_field "$config_19" "lv_name"
    local lv_19="$CONFIG_FIELD_RET"
    # From man lvm: The valid characters for VG and LV names are: a-z A-Z 0-9 + _ . -
    if [ -z "$lv_19" ] ; then
      error "Invalid lv($lv_19) for $config_19";
      return
    fi
    case $lv_19 in
      (*[!0-9a-zA-Z+_.-]*|'') error "Invalid lv($lv_19) for $config_19"; return;;
    esac

    config_field "$config_19" "snapshot_size"
    local size_19="$CONFIG_FIELD_RET"
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
  VALIDATE_CONFIG_RET=1
}
