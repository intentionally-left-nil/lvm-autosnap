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

remove_invalid_snapshots () {
  lvm_get_volumes 'lv_tags=autosnap:true,origin=~^.+$,lv_snapshot_invalid>0'
  local snapshots="$lvm_get_volumes_ret"
  local oldifs="$IFS"
  IFS="
"
  local snapshot
  for snapshot in $snapshots ; do
    lvol_display_name "$snapshot"
    local snapshot_name="$lvol_display_name_ret"
    warn "$snapshot_name is invalid (probably full). Removing it"
    lvm_remove_snapshot "$snapshot"

    lvol_tag "$snapshot" "primary"
    if [ "$lvol_tag_ret" = "true" ] ; then
      lvol_field "$snapshot" "lv_uuid"
      local group_id="$lvol_field_ret"
      lvm_get_volumes "lv_tags=autosnap:true,origin=~^.+$,lv_tags=group_id:${group_id}"
      local group_snapshots="$lvm_get_volumes_ret"
      for group_snapshot in $group_snapshots ; do
        lvol_display_name "$group_snapshot"
        warn "Also removing $lvol_display_name_ret (in the same snapshot group as $snapshot_name)"
        lvm_remove_snapshot "$group_snapshot"
      done
    fi
  done
  IFS="$oldifs"
}

root_pending_count () {
  root_pending_count_ret=0
  lvm_get_volumes "lv_tags=autosnap:true,lv_tags=primary:true" "-lv_time"
  local oldifs="$IFS"
  IFS="
"
  at_index "$lvm_get_volumes_ret" 0
  local lvol="$at_index_ret"
  IFS="$oldifs"

  if [ -n "$lvol" ] ; then
    lvol_tag "$lvol" "pending"
    root_pending_count_ret="$lvol_tag_ret"
    is_number "$root_pending_count_ret"
    if [ -z "$is_number_ret" ] ; then
      root_pending_count_ret=0
    fi
  fi
}
