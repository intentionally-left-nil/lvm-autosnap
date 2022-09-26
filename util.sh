#! /bin/ash
# shellcheck shell=dash

is_number () {
  debug "func: is_number"
  local item_1="${1:-}"
  is_number_ret=
  case $item_1 in
    (*[!0-9]*|'') ;;
    (*)           is_number_ret=1;;
  esac
}

increment () {
  debug "func: increment"
  local val_2="$1"
  is_number "$val_2"
  if [ -z "$is_number_ret" ] ; then
    exit 1
  fi
  increment_ret="$((val_2+1))"
}

length () {
  debug "func: length"
  local items_3="${1:-}"
  length_ret=0
  if [ -n "$items_3" ] ; then
    # shellcheck disable=SC2086
    set -- $items_3 || exit "$?"
    length_ret="$#"
  fi
}

at_index () {
  debug "func: at_index"
  local items_4="${1:-}"
  local i_4="$2"
  # index is 0 based, but the positional args are 1-based
  increment "$i_4"
  i_4="$increment_ret"
  at_index_ret=
  if [ -n "$items_4" ] ; then
    # shellcheck disable=SC2086
    set -- $items_4 || exit "$?"
    if [ "$i_4" -le "$#" ] ; then
      at_index_ret=$(eval "echo \${$i_4}")
    fi
  fi
}

header_index () {
  debug "func: header_index"
  local headers_5="$1"
  local name_5="$2"
  header_index_ret=0
  local oldifs_5="$IFS"
  IFS=","
  local header_5

  for header_5 in $headers_5 ; do
    if [ "$header_5" = "$name_5" ] ; then
      IFS="$oldifs_5"
      return
    fi
    increment "$header_index_ret"
    header_index_ret="$increment_ret"
  done
  IFS="$oldifs_5"
  error "Missing header $name_5"
  press_enter_to_boot 1
}

field_by_header () {
  debug "func: field_by_header"
  local row_6="$1"
  local headers_6="$2"
  local name_6="$3"
  local delim_6="$4"
  local oldifs_6="$IFS"

  header_index "$headers_6" "$name_6"
  IFS="$delim_6"
  at_index "$row_6" "$header_index_ret"
  IFS="$oldifs_6"
  trim "$at_index_ret"
  field_by_header_ret="$trim_ret"
}

trim() {
  debug "func:trim"
  #https://stackoverflow.com/a/3352015/3029173
  local str_7="$1"
  # remove leading whitespace characters
  str_7="${str_7#"${str_7%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  str_7="${str_7%"${str_7##*[![:space:]]}"}"
  trim_ret="$str_7"
}

press_enter_to_boot () {
  debug 
  local code_8="${1:-1}"
  if [ -n "${INTERACTIVE:-}" ] ; then
    get_user_input "Press (enter) to continue booting"
  fi
  exit "$code_8"
}

get_user_input () {
  debug "func: get_user_input"
  local prompt_9="$1"
  get_user_input_ret=
  printf "\n\n%s \n" "$prompt_9"
  # Allow failures here, just treat it as if the user didn't type anything
  read -r get_user_input_ret
}

error () {
  local message_10="$1"
  printf "[lvm-autosnap](error) %s\n" "$message_10" >&2
}

warn () {
  local message_11="$1"
  if [ -n "${LOG_LEVEL:-2}" ] && [ "${LOG_LEVEL:-2}" -ge 1 ] ; then
    printf "[lvm-autosnap](warn) %s\n" "$message_11" >&2
  fi
}

info () {
  local message_12="$1"
  if [ -n "${LOG_LEVEL:-2}" ] && [ "${LOG_LEVEL:-2}" -ge 2 ] ; then
    printf "[lvm-autosnap](info) %s\n" "$message_12"
  fi
}

prompt () {
  local message_13="$1"
  printf "%s\n" "$message_13"
}

debug () {
  local message_14="$1"
  if [ -n "${LOG_LEVEL:-2}" ] && [ "${LOG_LEVEL:-2}" -ge 3 ] ; then
    printf "[lvm-autosnap](debug) %s\n" "$message_14"
  fi
}
