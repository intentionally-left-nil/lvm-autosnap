#! /bin/ash
# shellcheck shell=dash

is_number () {
  debug "func: is_number"
  local item_1="${1:-}"
  IS_NUMBER_RET=
  case $item_1 in
    (*[!0-9]*|'') ;;
    (*)           IS_NUMBER_RET=1;;
  esac
}

increment () {
  debug "func: increment"
  local val_2="$1"
  is_number "$val_2"
  if [ -z "$IS_NUMBER_RET" ] ; then
    exit 1
  fi
  INCREMENT_RET="$((val_2+1))"
}

length () {
  debug "func: length"
  local items_3="${1:-}"
  LENGTH_RET=0
  if [ -n "$items_3" ] ; then
    # shellcheck disable=SC2086
    set -- $items_3 || exit "$?"
    LENGTH_RET="$#"
  fi
}

at_index () {
  debug "func: at_index"
  local items_4="${1:-}"
  local i_4="$2"
  # index is 0 based, but the positional args are 1-based
  increment "$i_4"
  i_4="$INCREMENT_RET"
  AT_INDEX_RET=
  if [ -n "$items_4" ] ; then
    # shellcheck disable=SC2086
    set -- $items_4 || exit "$?"
    if [ "$i_4" -le "$#" ] ; then
      AT_INDEX_RET=$(eval "echo \${$i_4}")
    fi
  fi
}

header_index () {
  debug "func: header_index"
  local headers_5="$1"
  local name_5="$2"
  HEADER_INDEX_RET=0
  local oldifs_5="$IFS"
  IFS=","
  local header_5

  for header_5 in $headers_5 ; do
    if [ "$header_5" = "$name_5" ] ; then
      IFS="$oldifs_5"
      return
    fi
    increment "$HEADER_INDEX_RET"
    HEADER_INDEX_RET="$INCREMENT_RET"
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
  at_index "$row_6" "$HEADER_INDEX_RET"
  IFS="$oldifs_6"
  trim "$AT_INDEX_RET"
  FIELD_BY_HEADER_RET="$TRIM_RET"
}

trim() {
  debug "func:trim"
  #https://stackoverflow.com/a/3352015/3029173
  local str_7="$1"
  # remove leading whitespace characters
  str_7="${str_7#"${str_7%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  str_7="${str_7%"${str_7##*[![:space:]]}"}"
  TRIM_RET="$str_7"
}

press_enter_to_boot () {
  debug "func: press_enter_to_boot"
  local code_8="${1:-1}"
  if [ -n "${INTERACTIVE:-}" ] ; then
    get_user_input "Press (enter) to continue booting"
  fi
  exit "$code_8"
}

get_user_input () {
  debug "func: get_user_input"
  local prompt_9="$1"
  GET_USER_INPUT_RET=
  printf "\n\n%s \n" "$prompt_9"
  # Allow failures here, just treat it as if the user didn't type anything
  read -r GET_USER_INPUT_RET
}

error () {
  local message_10="$1"
  printf "[lvm-autosnap](error) %s\n" "$message_10" >&2
}

warn () {
  local message_11="$1"
  if [ -n "${LOG_LEVEL:-0}" ] && [ "${LOG_LEVEL:-0}" -ge 1 ] ; then
    printf "[lvm-autosnap](warn) %s\n" "$message_11" >&2
  fi
}

info () {
  local message_12="$1"
  if [ -n "${LOG_LEVEL:-0}" ] && [ "${LOG_LEVEL:-0}" -ge 2 ] ; then
    printf "[lvm-autosnap](info) %s\n" "$message_12"
  fi
}

prompt () {
  local message_13="$1"
  printf "%s\n" "$message_13"
}

debug () {
  local message_14="$1"
  if [ -n "${LOG_LEVEL:-0}" ] && [ "${LOG_LEVEL:-0}" -ge 3 ] ; then
    printf "[lvm-autosnap](debug) %s\n" "$message_14"
  fi
}
