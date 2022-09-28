#! /bin/ash
# shellcheck shell=dash
# shellcheck disable=SC2086

set -u

# shellcheck source=util.sh
. "$SCRIPT_PATH/util.sh"

lvol_columns() {
  debug "func: lvol_columns"
  LVOL_COLUMNS_RET="vg_name,lv_name,lv_uuid,lv_tags,lv_time,origin,lv_snapshot_invalid"
}

lvol_field () {
  debug "func: lvol_field"
  local lvol_20="$1"
  local name_20="$2"

  lvol_columns
  field_by_header "$lvol_20" "$LVOL_COLUMNS_RET" "$name_20" "|"
  LVOL_FIELD_RET="$FIELD_BY_HEADER_RET"
}

lvol_tag () {
  debug "func: lvol_tag"
  local lvol_21="$1"
  local key_21="$2"
  LVOL_TAG_RET=
  lvol_field "$lvol_21" lv_tags
  local tags_21="$LVOL_FIELD_RET"
  local oldifs_21="$IFS"
  local tag_21
  IFS=","

  for tag_21 in $tags_21 ; do
    IFS=":"
    length "$tag_21"
    if [ "$LENGTH_RET" -ne 2 ] ; then
      continue
    fi
    at_index "$tag_21" 0
    if [ "$AT_INDEX_RET" = "$key_21" ] ; then
      at_index "$tag_21" 1
      LVOL_TAG_RET="$AT_INDEX_RET"
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
  local vg_22="$LVOL_FIELD_RET"
  lvol_field "$lvol_22" "lv_name"
  local lv_22="$LVOL_FIELD_RET"
  lvol_field "$lvol_22" "origin"
  local origin_22="$LVOL_FIELD_RET"
  if [ -z "$origin_22" ] ; then
    LVOL_DISPLAY_NAME_RET="$vg_22/$lv_22"
  else
    lvol_field "$lvol_22" "lv_time"
    LVOL_DISPLAY_NAME_RET="$vg_22/$lv_22 (snapshot of $origin_22 @ $LVOL_FIELD_RET)"
  fi
}

first_lvol () {
  local lvols_23="$1"
  local oldifs_23="$IFS"
  IFS="
"
  at_index "$lvols_23" 0
  FIRST_LVOL_RET="$AT_INDEX_RET"
  IFS="$oldifs_23"
}
