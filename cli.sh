#! /bin/sh
# shellcheck disable=SC3043

# shellcheck source=core.sh
. "$SCRIPT_PATH/core.sh"

# shellcheck source=lvol.sh
. "$SCRIPT_PATH/lvol.sh"

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

# shellcheck source=config.sh
. "${SCRIPT_PATH}/config.sh"

usage () {
  debug: "func: usage"
  prompt "lvm-autosnap COMMAND OPTIONS"
  prompt "Available commands:"
  prompt "mark_good - Mark the stapshot of the current boot as known-good"
  prompt "list - Display a list of snapshot groups on the system"
  prompt "delete [snapshot_group_id] - Deletes a snapshot group by its group_id"
}

cli_main () {
  debug "func: cli_main"
  config_set_defaults
  load_config_from_env
  if [ -n "$LOG_LEVEL" ] && [ "$LOG_LEVEL" -ge 4 ] ; then
    # log all commands
    set -x
  fi
  validate_config

  if [ -z "$VALIDATE_CONFIG_RET" ] ; then
    exit 1
  fi

  if [ "$#" -lt 1 ] ; then
    usage
    exit 1
  fi

  case "$1" in
  (mark_good) cli_mark_good; return;;
  (list) cli_list_snapshots; return;;
  (delete) cli_delete_snapshot_group "${2:-}"; return;;
  esac
}

cli_mark_good () {
  debug "func: cli_mark_good"
  lvm_get_volumes "lv_tags=autosnap:true,lv_tags=primary:true,lv_tags=current_boot:true" "-lv_time"
  first_lvol "$LVM_GET_VOLUMES_RET"
  local lvol_40="$FIRST_LVOL_RET"
  if [ -z "$lvol_40" ] ; then
    info "No primary snapshots exist. Nothing to do"
    exit 0
  fi
  lvol_tag "$lvol_40" "pending"
  local pending_count_40="$LVOL_TAG_RET"
  is_number "$pending_count_40"
  if [ -z "$IS_NUMBER_RET" ] ; then
    warn "The pending count($pending_count_40) is unexpectedly not a number"
    exit 1
  fi
  lvol_display_name "$lvol_40"
  local lvol_name_40="$LVOL_DISPLAY_NAME_RET"
  if [ "$pending_count_40" -le 0 ] ; then
    info "($lvol_name_40) is already known-good. Nothing to do"
  else
    lvm_add_tag "$lvol_40" "pending:0"
    lvm_del_tag "$lvol_40" "pending:$pending_count_40"

    info "Changed $lvol_name_40 to be a known-good snapshot"
  fi
}

cli_list_snapshots () {
  debug "func: cli_list_snapshots"

  lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=primary:true' "-lv_time"
  local primary_vols_41="$LVM_GET_VOLUMES_RET"
  if [ -z "$primary_vols_41" ] ; then
    return
  fi
  local oldifs_41="$IFS"
  local primary_lvol_41
  IFS="
"
  for primary_lvol_41 in $primary_vols_41; do
    lvol_tag "$primary_lvol_41" "group_id"
    local group_id_41="$LVOL_TAG_RET"
    if [ -z "$group_id_41" ] ; then
      continue
    fi
    prompt "snapshot group $group_id_41"
    printf "vg_name\tlv_name\torigin\ttime_created\n"
    lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=group_id:'"$group_id_41" "origin"
    local group_vols_41="$LVM_GET_VOLUMES_RET"
    local lvol_41
    for lvol_41 in $group_vols_41; do
      lvol_field "$lvol_41" "vg_name"
      local vg_41="$LVOL_FIELD_RET"
      lvol_field "$lvol_41" "lv_name"
      local lv_41="$LVOL_FIELD_RET"
      lvol_field "$lvol_41" "origin"
      local origin_41="$LVOL_FIELD_RET"
      lvol_field "$lvol_41" "lv_time"
      local time_41="$LVOL_FIELD_RET"
      printf '%s\t%s\t%s\t%s\n' "$vg_41" "$lv_41" "$origin_41" "$time_41"
    done
    printf '\n\n'
  done
  IFS="$oldifs_41"
}

cli_delete_snapshot_group () {
  debug func "cli_delete_snapshot_group"
  local group_id_42="$1"
  if [ -z "$group_id_42" ]; then
    usage
    exit 1
  fi
  lvm_remove_snapshot_group "$group_id_42"
}
