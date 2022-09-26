#! /bin/ash
# shellcheck shell=dash

# shellcheck source=lvm-wrapper.sh
. "$SCRIPT_PATH/lvm-wrapper.sh"

# shellcheck source=lvol.sh
. "$SCRIPT_PATH/lvol.sh"

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

# shellcheck source=config.sh
. "$SCRIPT_PATH/config.sh"

main () {
  config_set_defaults
  lvm_del_tags_from_all "current_boot:true"
  load_config_from_env
  local cmdline_31
  cmdline_31="$(cat /proc/cmdline)"
  # shellcheck disable=SC2181
  if [ "$?" -eq 0 ] ; then
    load_config_from_cmdline "$cmdline_31"
  else
    warn "error reading from /proc/cmdline"
  fi

  if [ -n "$LOG_LEVEL" ] && [ "$LOG_LEVEL" -ge 4 ] ; then
    # log all commands
    set -x
  fi
  debug "func: main"

  validate_config
  if [ -z "$validate_config_ret" ] ; then
    press_enter_to_boot 1
  fi

  remove_invalid_snapshots
  root_pending_count
  local pending_count_31="$root_pending_count_ret"

  local should_restore_31=
  local should_backup_31=1
  if [ "$MODE" = "restore" ] ; then
    should_restore_31=1
  elif [ "$MODE" = "backup" ] ; then
    true
  elif [ "$RESTORE_AFTER" -gt 0 ] ; then
    if [ "$pending_count_31" -ge "$RESTORE_AFTER" ] ; then
      should_restore_31=1
      info "The system has failed to boot ${root_pending_count_ret} times"
    fi
  fi

  if [ -n "$should_restore_31" ] ; then
    restore
    should_backup_31="$restore_ret"
    pending_count_31=0
  fi

  if [ -n "$should_backup_31" ] ; then
    remove_old_snapshots
    if [ -z "$remove_old_snapshots_ret" ] ; then
      press_enter_to_boot 1
    fi
    backup "$pending_count_31"
  fi
}

backup () {
  debug "func: backup"
  local pending_count_32="$1"
  increment "$pending_count_32"
  pending_count_32="$increment_ret"
  local oldifs_32="$IFS"
  IFS="/"
  # shellcheck disable=SC2086
  set -- $CONFIGS || exit "$?"
  local root_config_32=$1
  shift
  IFS="$oldifs_32"

  # Create the root snapshot
  config_field "$root_config_32" "vg_name"
  local vg_32="$config_field_ret"
  config_field "$root_config_32" "lv_name"
  local lv_32="$config_field_ret"
  config_field "$root_config_32" "snapshot_size"
  local size_32="$config_field_ret"

  lvm_create_snapshot "$vg_32" "$lv_32" "$size_32" "$pending_count_32" "true"
  local snapshot_lv_32="$lvm_create_snapshot_ret"

  lvm_get_volumes "vg_name=$vg_32,lv_name=$snapshot_lv_32,lv_tags=autosnap:true"
  local lvol_32="$lvm_get_volumes_ret"
  if [ -z "$lvol_32" ] ; then
    error "Could not find the newly created snapshot $vg_32/$snapshot_lv_32"
    press_enter_to_boot
  fi
  lvol_field "$lvol_32" "lv_uuid"
  local group_id_32="$lvol_field_ret"
  
  lvm_add_tag "$lvol_32" "group_id:$group_id_32"

  # For every other config, also create a snapshot, making sure to set the group_id to the root uuid
  local config_32
  while [ "$#" -gt 0 ] ; do
    config_32="$1"
    config_field "$config_32" "vg_name"
    vg_32="$config_field_ret"
    config_field "$config_32" "lv_name"
    lv_32="$config_field_ret"
    config_field "$config_32" "snapshot_size"
    size_32="$config_field_ret"

    lvm_create_snapshot "$vg_32" "$lv_32" "$size_32" 0 "false" "$group_id_32"
    shift
  done

  lvm_get_volumes "lv_tags=group_id:$group_id_32"
  local snapshots_32="$lvm_get_volumes_ret"
  IFS="
"
  info "Created new snapshot group $group_id_32"
  for lvol_32 in $snapshots_32; do
    lvol_display_name "$lvol_32"
    info "Created $lvol_display_name_ret"
  done
  IFS="$oldifs_32"
}

restore () {
  debug "func: restore"
  restore_ret=
  get_group_id_to_restore
  local group_id_33="$get_group_id_to_restore_ret"
  if [ -n "$group_id_33" ] ; then
    prompt "Do you wish to continue? This is your last chance to abort"
    get_user_input "Confirm by typing I_HAVE_BACKUPS_ELSEWHERE:"
    if [ "$get_user_input_ret" != "I_HAVE_BACKUPS_ELSEWHERE" ] ; then
      return
    fi
    lvm_restore_snapshot_group "$group_id_33"
    prompt "Finished restoring snapshot group $group_id_33"
    if [ -n "${INTERACTIVE:-}" ] ; then
      get_user_input "Press (enter) to continue"
    fi
    restore_ret=1
  fi
}

get_group_id_to_restore () {
  debug "func: restore_from_snapshots"
  get_group_id_to_restore_ret=
  lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=primary:true,lv_tags=pending:0' "-lv_time"
  local snapshots_34="$lvm_get_volumes_ret"
  local oldifs_34="$IFS"
  IFS="
"
  length "$snapshots_34"
  if [ "$length_ret" -eq 0 ] ; then
    error "There are no known-good snapshots to restore from"
    return
  fi

  prompt "Restore snapshots are available for the following times"
  local snapshot_34
  local i_34=1
  for snapshot_34 in $snapshots_34; do
    lvol_field "$snapshot_34" "lv_time"
    prompt "$i_34) $lvol_field_ret"
    increment "$i_34"
    i_34="$increment_ret"
  done

  get_user_input "choose a number (or n to abort):"
  local choice_34=0
  case $get_user_input_ret in
    (*[!0-9]*|'') error "Aborting"; return;;
    (*)           choice_34="$((get_user_input_ret))";;
  esac

  length "$snapshots_34"

  if [ "$choice_34" -lt 1 ] || [ "$choice_34" -gt "$length_ret" ] ; then
    error "Aborting"
    return
  fi
  at_index "$snapshot_34" "$((choice_34-1))"
  snapshot_34="$at_index_ret"

  lvol_tag "$snapshot_34" "group_id"
  IFS="$oldifs_34"
  get_group_id_to_restore_ret="$lvol_tag_ret"
}

remove_invalid_snapshots () {
  debug "func: remove_invalid_snapshots"
  local watchdog_35=0
  while [ "$watchdog_35" -lt 100 ] ; do
    increment "$watchdog_35"
    watchdog_35="$increment_ret"
    lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_snapshot_invalid>0' 'lv_time'
    first_lvol "$lvm_get_volumes_ret"
    local lvol_35="$first_lvol_ret"
    lvol_tag "$lvol_35" "group_id"
    local group_id_35="$lvol_tag_ret"
    if [ -n "$group_id_35" ] ; then
      lvol_display_name "$lvol_35"
      info "$lvol_display_name_ret is invalid (probably full). Removing group $group_id_35"
      remove_snapshot_group "$group_id_35"
    else
      break
    fi
  done
}

remove_old_snapshots () {
  debug "func: remove_old_snapshots"
  remove_old_snapshots_ret=
  local oldifs_36="$IFS"
  local watchdog_36=0
  while [ "$watchdog_36" -lt 100 ] ; do
    increment "$watchdog_36"
    watchdog_36="$increment_ret"
    lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=primary:true'
    IFS="
"
    length "$lvm_get_volumes_ret"
    if [ "$length_ret" -lt "$MAX_SNAPSHOTS" ] ; then
      remove_old_snapshots_ret=1
      break
    fi
    remove_old_snapshot

    if [ -z "$remove_old_snapshot_ret" ] ; then
      break
    fi
  done
  IFS="$oldifs_36"
}

remove_old_snapshot () {
  debug "func: remove_old_snapshot"
  remove_old_snapshot_ret=
  lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=primary:true,lv_tags!=pending:0' "lv_time"
  first_lvol "$lvm_get_volumes_ret"
  local lvol_37="$first_lvol_ret"
  local group_id_37=
  if [ -z "$lvol_37" ] ; then
    lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=primary:true,lv_tags=pending:0' "lv_time"
    first_lvol "$lvm_get_volumes_ret"
    lvol_37="$first_lvol_ret"
  fi

  if [ -z "$lvol_37" ] ; then
    error "Could not find any snapshot to remove"
    return
  fi
  lvol_display_name "$lvol_37"
  local name_37="$lvol_display_name_ret"

  lvol_tag "$lvol_37" "group_id"
  group_id_37="$lvol_tag_ret"
  if [ -z "$group_id_37" ] ; then
    error "$name_37 does not contain a group_id"
    return
  fi

  info "Removing $name_37 (and group $group_id_37) to make room for new snapshots"
  remove_snapshot_group "$group_id_37"
  if [ -n "$remove_snapshot_group_ret" ] ; then
    remove_old_snapshot_ret=1
  fi
}

remove_snapshot_group () {
  debug "func: remove_snapshot_group"
  remove_snapshot_group_ret=
  local group_id_38="$1"
  lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=group_id:'"$group_id_38"
  local snapshots_38="$lvm_get_volumes_ret"
  local oldifs_38="$IFS"
  IFS="
"
  local snapshot_38
  info "Removing snapshot group $group_id_38"

  for snapshot_38 in $snapshots_38 ; do
    lvm_remove_snapshot "$snapshot_38"
    remove_snapshot_group_ret=1
  done
  IFS="$oldifs_38"
}

root_pending_count () {
  debug "func: root_pending_count"
  root_pending_count_ret=0
  lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=primary:true' "-lv_time"
  first_lvol "$lvm_get_volumes_ret"
  local lvol_39="$first_lvol_ret"
  if [ -n "$lvol_39" ] ; then
    lvol_tag "$lvol_39" "pending"
    root_pending_count_ret="$lvol_tag_ret"
    is_number "$root_pending_count_ret"
    if [ -z "$is_number_ret" ] ; then
      root_pending_count_ret=0
    fi
  fi
}
