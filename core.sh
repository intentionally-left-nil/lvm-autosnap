#! /bin/ash
# shellcheck shell=dash

set -u

# shellcheck source=lvm-wrapper.sh
. "$SCRIPT_PATH/lvm-wrapper.sh"

# shellcheck source=lvol.sh
. "$SCRIPT_PATH/lvol.sh"

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

remove_invalid_snapshots () {
  lvm_get_volumes "lv_tags=autosnap:true"
  local snapshots="$lvm_get_volumes_ret"
  local oldifs="$IFS"
  IFS="
"
  local snapshot
  for snapshot in $snapshots ; do
    lvol_field "$snapshot" "lv_snapshot_invalid"
    if [ -n "$lvol_field_ret" ] ; then
      # just to double check, make double sure it's a snapshot
      lvol_field "$snapshot" "origin"
      if [ -n "$lvol_field_ret" ]; then
        lvol_field "$snapshot" "vg_name"
        local vg="$lvol_field_ret"
        lvol_field "$snapshot" "lv_name"
        local lv="$lvol_field_ret"
        warn "$vg/$lv is invalid (probably full). Removing it"
        lvm_remove_snapshot "$vg" "$lv"
      fi
    fi
  done
}
