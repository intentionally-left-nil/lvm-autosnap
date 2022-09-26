#! /bin/sh
# shellcheck disable=SC3043

set -uf
SCRIPT_PATH="${0%/*}"

# shellcheck source=config.sh
. "${SCRIPT_PATH}/config.sh"

# shellcheck source=lvm-wrapper.sh
. "${SCRIPT_PATH}/lvm-wrapper.sh"

service_main () {
  config_set_defaults
  load_config_from_env
  validate_config

  if [ -z "$validate_config_ret" ] ; then
    exit 1
  fi

  lvm_get_volumes "lv_tags=autosnap:true,lv_tags=primary:true,lv_tags=current_boot:true" "-lv_time"
  first_lvol "$lvm_get_volumes_ret"
  local lvol_40="$first_lvol_ret"
  if [ -z "$lvol_40" ] ; then
    info "No primary snapshots exist. Nothing to do"
    exit 0
  fi
  lvol_tag "$lvol_40" "pending"
  local pending_count_40="$lvol_tag_ret"
  is_number "$pending_count_40"
  if [ -z "$is_number_ret" ] ; then
    warn "The pending count($pending_count_40) is unexpectedly not a number"
    exit 1
  fi
  lvol_display_name "$lvol_40"
  local lvol_name_40="$lvol_display_name_ret"
  if [ "$pending_count_40" -le 0 ] ; then
    info "($lvol_name_40) is already known-good. Nothing to do"
  else
    lvm_add_tag "$lvol_40" "pending:0"
    lvm_del_tag "$lvol_40" "pending:$pending_count_40"

    info "Changed $lvol_name_40 to be a known-good snapshot"
  fi
}

service_main
