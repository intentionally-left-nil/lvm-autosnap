#! /bin/ash
# shellcheck shell=dash

set -u

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
  load_config_from_env
  local cmdline
  cmdline="$(cat /proc/cmdline)"
  # shellcheck disable=SC2181
  if [ "$?" -eq 0 ] ; then
    load_config_from_cmdline "$cmdline"
  else
    warn "error reading from /proc/cmdline"
  fi

  if [ -n "$LOG_LEVEL" ] && [ "$LOG_LEVEL" -ge 3 ] ; then
    # log all commands
    set -x
  fi
  debug "func: main"

  validate_config
  if [ -z "$validate_config_ret" ] ; then
    press_enter_to_boot 1
  fi

  remove_invalid_snapshots
  create_new_snapshots
}

create_new_snapshots () {
  root_pending_count
  increment "$root_pending_count_ret"
  local pending_count="$increment_ret"
  local oldifs="$IFS"
  IFS="/"
  # shellcheck disable=SC2086
  set -- $CONFIGS || exit "$?"
  local root_config=$1
  shift
  IFS="$oldifs"

  echo "root_config is $root_config"

  # Create the root snapshot
  config_field "$root_config" "vg_name"
  local vg="$config_field_ret"
  config_field "$root_config" "lv_name"
  local lv="$config_field_ret"
  config_field "$root_config" "snapshot_size"
  local size="$config_field_ret"

  lvm_create_snapshot "$vg" "$lv" "$size" "$pending_count" "true"
  local snapshot_lv="$lvm_create_snapshot_ret"

  lvm_get_volumes "vg_name=$vg,lv_name=$snapshot_lv,lv_tags=autosnap:true"
  local lvol="$lvm_get_volumes_ret"
  if [ -z "$lvol" ] ; then
    error "Could not find the newly created snapshot $vg/$snapshot_lv"
    press_enter_to_boot
  fi
  lvol_field "$lvol" "lv_uuid"
  local group_id="$lvol_field_ret"
  
  lvm_add_tag "$lvol" "group_id:$group_id"

  # For every other config, also create a snapshot, making sure to set the group_id to the root uuid
  while [ "$#" -gt 0 ] ; do
    config="$1"
    config_field "$config" "vg_name"
    vg="$config_field_ret"
    config_field "$config" "lv_name"
    lv="$config_field_ret"
    config_field "$config" "snapshot_size"
    size="$config_field_ret"

    lvm_create_snapshot "$vg" "$lv" "$size" 0 "false" "$group_id"
    shift
  done

  lvm_get_volumes "lv_tags=group_id:$group_id"
  local snapshots="$lvm_get_volumes_ret"
  IFS="
"
  info "Created new snapshot group $group_id"
  for lvol in $snapshots; do
    lvol_display_name "$lvol"
    info "Created $lvol_display_name_ret"
  done
}

remove_invalid_snapshots () {
  lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_snapshot_invalid>0'
  local snapshots="$lvm_get_volumes_ret"
  local oldifs="$IFS"
  IFS="
"
  local snapshot
  for snapshot in $snapshots ; do
    lvol_tag "$snapshot" "group_id"
    local group_id="$lvol_tag_ret"
    if [ -n "$group_id" ] ; then
      lvol_display_name "$snapshot"
      warn "$lvol_display_name_ret is invalid (probably full). Removing group $group_id"
      remove_snapshot_group "$group_id"
    fi
  done
  IFS="$oldifs"
}

remove_snapshot_group () {
  local group_id="$1"
  lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_tags=group_id:'"$group_id"
  local oldifs="$IFS"
  IFS="
"
  local snapshot
  for snapshot in $snapshots ; do
    lvm_remove_snapshot "$snapshot"
  done
  IFS="$oldifs"
}

root_pending_count () {
  root_pending_count_ret=0
  lvm_get_volumes "lv_tags=autosnap:true,lv_tags=primary:true" "-lv_time"
  first_lvol "$lvm_get_volumes_ret"
  local lvol="$first_lvol_ret"
  if [ -n "$lvol" ] ; then
    lvol_tag "$lvol" "pending"
    root_pending_count_ret="$lvol_tag_ret"
    is_number "$root_pending_count_ret"
    if [ -z "$is_number_ret" ] ; then
      root_pending_count_ret=0
    fi
  fi
}
