#! /bin/ash
# shellcheck shell=dash

# shellcheck source=util.sh
. "${SCRIPT_PATH?:}/util.sh"

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

