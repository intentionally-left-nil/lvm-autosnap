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
  local lvol_20="$1"
  local name_20="$2"

  lvol_columns
  field_by_header "$lvol_20" "$lvol_columns_ret" "$name_20" "|"
  lvol_field_ret="$field_by_header_ret"
}

lvol_tag () {
  debug "func: lvol_tag"
  local lvol_21="$1"
  local key_21="$2"
  lvol_tag_ret=
  lvol_field "$lvol_21" lv_tags
  local tags_21="$lvol_field_ret"
  local oldifs_21="$IFS"
  local tag_21
  IFS=","

  for tag_21 in $tags_21 ; do
    IFS=":"
    at_index "$tag_21" 0
    if [ "$at_index_ret" = "$key_21" ] ; then
      at_index "$tag_21" 1
      lvol_tag_ret="$at_index_ret"
      break
    fi
    IFS=","
  done
  IFS="$oldifs_21"
}

lvol_display_name () {
  debug "func lvol_display_name"
  local lvol_22="$1"

  lvol_field "$lvol_22" "vg_name"
  local vg_22="$lvol_field_ret"
  lvol_field "$lvol_22" "lv_name"
  local lv_22="$lvol_field_ret"
  lvol_field "$lvol_22" "origin"
  local origin_22="$lvol_field_ret"
  if [ -z "$origin_22" ] ; then
    lvol_display_name_ret="$vg_22/$lv_22"
  else
    lvol_field "$lvol_22" "lv_time"
    lvol_display_name_ret="$vg_22/$lv_22 (snapshot of $origin_22 @ $lvol_field_ret)"
  fi
}

first_lvol () {
  local lvols_23="$1"
  local oldifs_23="$IFS"
  IFS="
"
  at_index "$lvols_23" 0
  first_lvol_ret="$at_index_ret"
  IFS="$oldifs_23"
}
