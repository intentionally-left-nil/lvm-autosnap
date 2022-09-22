#! /bin/ash
# shellcheck shell=dash
# shellcheck disable=SC2086

set -u

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

lvol_columns() {
  debug "func: lvol_columns"
  lvol_columns_ret="vg_name,lv_name,lv_uuid,lv_tags,lv_time,origin,lv_snapshot_invalid"
}

lvol_field () {
  debug "func: lvol_field"
  local lvol="$1"
  local name="$2"

  lvol_columns
  field_by_header "$lvol" "$lvol_columns_ret" "$name" "|"
  lvol_field_ret="$field_by_header_ret"
}

lvol_tag () {
  debug "func: lvol_tag"
  local lvol="$1"
  local key="$2"
  lvol_tag_ret=
  lvol_field "$lvol" lv_tags
  local tags="$lvol_field_ret"
  local oldifs="$IFS"
  local tag
  IFS=","

  for tag in $tags ; do
    IFS=":"
    at_index "$tag" 0
    if [ "$at_index_ret" = "$key" ] ; then
      at_index "$tag" 1
      lvol_tag_ret="$at_index_ret"
      break
    fi
    IFS=","
  done
  IFS="$oldifs"
}

lvol_display_name () {
  debug "func lvol_display_name"
  local lvol="$1"
  lvol_field "$lvol" "vg_name"
  local vg="$lvol_field_ret"

  lvol_field "$lvol" "origin"
  local origin="$lvol_field_ret"
  if [ -z "$origin" ] ; then
    lvol_field "$lvol" "lv_name"
    local lv="$lvol_field_ret"
    lvol_display_name_ret="$vg/$lv"
  else
    lvol_field "$lvol" "lv_time"
    local ts="$lvol_field_ret"
    lvol_display_name_ret="snapshot of $vg/$origin @ $ts"
  fi
}
