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
  local output
  output="$(lvm lvcreate --permission=r --size="$size" --snapshot --monitor n --addtag autosnap:true --addtag "pending:$pending_count" "$vg/$lv" 2>&1)"
  lvm_handle_error "$?" "$output"
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
  local vg="$1"
  local lv="$2"
  info "Removing old snapshot $vg/$lv"
  local output

  output="$(lvm lvremove "$vg/$lv" -y 2>&1)"
  lvm_handle_error "$?" "$output"
}

lvm_restore_snapshot () {
  debug "func: lvm_restore_snapshot"
  local snapshot="$1"
  warn "Restoring from snapshot $snapshot"
  # Since this command takes awhile, we just want to do the simple thing and display everything to the screen
  # That way the user will see the in-progress restore state
  lvm lvconvert --merge "$snapshot"
  lvm_handle_error "$?" ""
}

lvm_add_tag () {
  debug "func: lvm_add_tag"
  local vg="$1"
  local lv="$2"
  local tag="$3"
  output="$(lvm lvchange --addtag "$tag" 2>&1)"
  lvm_handle_error "$?" "$output"
}

lvm_del_tag () {
  debug "func: lvm_del_tag"
  local vg="$1"
  local lv="$2"
  local tag="$3"
  output="$(lvm lvchange --deltag "$tag" 2>&1)"
  lvm_handle_error "$?" "$output"
}


lvm_handle_error () {
  local code=$1
  local output=$2
  debug "$output"
  if [ "$code" -ne 0  ] ; then
    if [ -n "$output" ] ; then
      error "$output"
    fi
    press_enter_to_boot "$code"
    exit "$code"
  fi
}

