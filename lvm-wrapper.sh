#! /bin/ash
# shellcheck shell=dash

set -u

# shellcheck source=lvol.sh
. "$SCRIPT_PATH/lvol.sh"

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

lvm_create_snapshot () {
  debug "func: lvm_create_snapshot"
  local vg="$1"
  local lv="$2"
  local size="$3"
  local pending_count="$4"
  local primary_snapshot="$5"
  local group_id="${6:-}"
  local output
  if [ -z "$group_id" ] ; then
    output="$(lvm lvcreate --permission=r --size="$size" --snapshot --monitor=n --addtag autosnap:true --addtag current_boot:true --addtag "pending:$pending_count" --addtag "primary:$primary_snapshot" "$vg/$lv" 2>&1)"
  else
    output="$(lvm lvcreate --permission=r --size="$size" --snapshot --monitor=n --addtag autosnap:true --addtag current_boot:true --addtag "pending:$pending_count" --addtag "primary:$primary_snapshot" --addtag "group_id:$group_id" "$vg/$lv" 2>&1)"
  fi
  lvm_handle_error "$?" "$output"
  local oldifs="$IFS"
  IFS=\"
  at_index "$output" 1
  lvm_create_snapshot_ret="$at_index_ret"
  IFS="$oldifs"
}

lvm_get_volumes () {
  local query="$1"
  local sort="${2:-lv_time}"
  lvol_columns
  lvm_get_volumes_ret=$(lvm lvs "--select=$query" "--sort=$sort" --noheadings --separator="|" "--options=$lvol_columns_ret")
  lvm_handle_error "$?" "$lvm_get_volumes_ret"
}

lvm_remove_snapshot () {
  debug "func: lvm_remove_snapshot"
  local lvol="$1"
  lvol_field "$lvol" "vg_name"
  local vg="$lvol_field_ret"
  lvol_field "$lvol" "lv_name"
  local lv="$lvol_field_ret"

  lvol_display_name "$lvol"
  info "Removing $lvol_display_name_ret"
  local output
  output="$(lvm lvremove "$vg/$lv" -y 2>&1)"
  lvm_handle_error "$?" "$output"
}

lvm_restore_snapshot_group () {
  debug "func: lvm_restore_snapshot_group"
  local group_id="$1"
  warn "Restoring snapshot_group $group_id"
  # Since this command takes awhile, we just want to do the simple thing and display everything to the screen
  # That way the user will see the in-progress restore state
  lvm lvconvert --merge "@group_id:${group_id}"
  lvm_handle_error "$?" ""
}

lvm_add_tag () {
  debug "func: lvm_add_tag"
  local lvol="$1"
  local tag="$2"

  lvol_field "$lvol" "vg_name"
  local vg="$lvol_field_ret"
  lvol_field "$lvol" "lv_name"
  local lv="$lvol_field_ret"
  local output
  output="$(lvm lvchange --addtag "$tag" "$vg/$lv" 2>&1)"
  lvm_handle_error "$?" "$output"
}

lvm_del_tag () {
  debug "func: lvm_del_tag"
  local lvol="$1"
  local tag="$2"

  lvol_field "$lvol" "vg_name"
  local vg="$lvol_field_ret"
  lvol_field "$lvol" "lv_name"
  local lv="$lvol_field_ret"

  local output
  output="$(lvm lvchange --deltag "$tag" "$vg/$lv" 2>&1)"
  lvm_handle_error "$?" "$output"
}

lvm_del_tags_from_all () {
  debug "func: lvm_del_tags_from_all"
  local tag="$1"
  output="$(lvm lvchange --deltag "$tag" "@$tag" 2>&1)"
  lvm_handle_error "$?" "$output"
}

lvm_handle_error () {
  local code=$1
  local output=$2
  debug "lvm output: $output"
  if [ "$code" -ne 0  ] ; then
    if [ -n "$output" ] ; then
      error "$output"
    fi
    press_enter_to_boot "$code"
    exit "$code"
  fi
}

