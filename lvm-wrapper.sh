#! /bin/ash
# shellcheck shell=dash

# shellcheck source=lvol.sh
. "$SCRIPT_PATH/lvol.sh"

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

lvm_create_snapshot () {
  debug "func: lvm_create_snapshot"
  local vg_24="$1"
  local lv_24="$2"
  local size_24="$3"
  local pending_count_24="$4"
  local primary_snapshot_24="$5"
  local group_id_24="${6:-}"
  local output_24
  if [ -z "$group_id_24" ] ; then
    output_24="$(lvm lvcreate --permission=r --size="$size_24" --snapshot --monitor=n --addtag autosnap:true --addtag current_boot:true --addtag "pending:$pending_count_24" --addtag "primary:$primary_snapshot_24" "$vg_24/$lv_24" 2>&1)"
  else
    output_24="$(lvm lvcreate --permission=r --size="$size_24" --snapshot --monitor=n --addtag autosnap:true --addtag current_boot:true --addtag "pending:$pending_count_24" --addtag "primary:$primary_snapshot_24" --addtag "group_id:$group_id_24" "$vg_24/$lv_24" 2>&1)"
  fi
  lvm_handle_error "$?" "$output_24"
  local oldifs_24="$IFS"
  IFS=\"
  at_index "$output_24" 1
  lvm_create_snapshot_ret="$at_index_ret"
  IFS="$oldifs_24"
}

lvm_get_volumes () {
  local query_25="$1"
  local sort_25="${2:-lv_time}"
  lvol_columns
  lvm_get_volumes_ret=$(lvm lvs "--select=$query_25" "--sort=$sort_25" --noheadings --separator="|" "--options=$lvol_columns_ret")
  lvm_handle_error "$?" "$lvm_get_volumes_ret"
}

lvm_remove_snapshot () {
  debug "func: lvm_remove_snapshot"
  local lvol_26="$1"
  lvol_field "$lvol_26" "vg_name"
  local vg_26="$lvol_field_ret"
  lvol_field "$lvol_26" "lv_name"
  local lv_26="$lvol_field_ret"

  lvol_display_name "$lvol_26"
  info "Removing $lvol_display_name_ret"
  local output_26
  output_26="$(lvm lvremove "$vg_26/$lv_26" -y 2>&1)"
  lvm_handle_error "$?" "$output_26"
}

lvm_restore_snapshot_group () {
  debug "func: lvm_restore_snapshot_group"
  local group_id_27="$1"
  warn "Restoring snapshot_group $group_id_27"
  # Since this command takes awhile, we just want to do the simple thing and display everything to the screen
  # That way the user will see the in-progress restore state
  lvm lvconvert --merge "@group_id:${group_id_27}"
  lvm_handle_error "$?" ""
}

lvm_add_tag () {
  debug "func: lvm_add_tag"
  local lvol_28="$1"
  local tag_28="$2"

  lvol_field "$lvol_28" "vg_name"
  local vg_28="$lvol_field_ret"
  lvol_field "$lvol_28" "lv_name"
  local lv_28="$lvol_field_ret"
  local output_28
  output_28="$(lvm lvchange --addtag "$tag_28" "$vg_28/$lv_28" 2>&1)"
  lvm_handle_error "$?" "$output_28"
}

lvm_del_tag () {
  debug "func: lvm_del_tag"
  local lvol_28="$1"
  local tag_28="$2"

  lvol_field "$lvol_28" "vg_name"
  local vg_28="$lvol_field_ret"
  lvol_field "$lvol_28" "lv_name"
  local lv_28="$lvol_field_ret"

  local output_28
  output_28="$(lvm lvchange --deltag "$tag_28" "$vg_28/$lv_28" 2>&1)"
  lvm_handle_error "$?" "$output_28"
}

lvm_del_tags_from_all () {
  debug "func: lvm_del_tags_from_all"
  local tag_29="$1"
  local output_29
  output_29="$(lvm lvchange --deltag "$tag_29" "@$tag_29" 2>&1)"
  lvm_handle_error "$?" "$output_29"
}

lvm_handle_error () {
  local code_30=$1
  local output_30=$2
  debug "lvm output: $output_30"
  if [ "$code_30" -ne 0  ] ; then
    if [ -n "$output_30" ] ; then
      error "$output_30"
    fi
    press_enter_to_boot "$code_30"
    exit "$code_30"
  fi
}

