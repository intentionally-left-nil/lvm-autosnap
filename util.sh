#! /bin/ash
# shellcheck shell=dash

set -u

is_number () {
  debug "func: is_number"
  local item="${1:-}"
  is_number_ret=
  case $item in
    (*[!0-9]*|'') ;;
    (*)           is_number_ret=1;;
  esac
}

increment () {
  debug "func: increment"
  local val="$1"
  is_number "$val"
  if [ -z "$is_number_ret" ] ; then
    exit 1
  fi
  increment_ret="$((val+1))"
}

at_index() {
  debug "func: at_index"
  local items="${1:-}"
  local i="$2"
  # index is 0 based, but the positional args are 1-based
  increment "$i"
  i="$increment_ret"
  at_index_ret=
  if [ -n "$items" ] ; then
    # shellcheck disable=SC2086
    set -- $items || exit "$?"
    if [ "$i" -le "$#" ] ; then
      at_index_ret=$(eval "echo \${$i}")
    fi
  fi
}

header_index () {
  debug "func: header_index"
  local headers="$1"
  local name="$2"
  header_index_ret=0
  local oldifs="$IFS"
  IFS=","
  local header

  for header in $headers ; do
    if [ "$header" = "$name" ] ; then
      IFS="$oldifs"
      return
    fi
    increment "$header_index_ret"
    header_index_ret="$increment_ret"
  done
  IFS="$oldifs"
  error "Missing header $name"
  press_enter_to_boot 1
}

field_by_header () {
  debug "func: field_by_header"
  local row="$1"
  local headers="$2"
  local name="$3"
  local oldifs="$IFS"

  header_index "$headers" "$name"
  IFS="|"
  at_index "$row" "$header_index_ret"
  IFS="$oldifs"
  trim "$at_index_ret"
  field_by_header_ret="$trim_ret"
}

trim () {
  local str="$1"
  trim_ret=

  # First, trim the leading whitespace, recursing if necessary
  # Split the string into the first character, and the remaining
  local first="${str%"${str#?}"}"
  local rest="${str#?}"
  # If the first character is a space, recurse on the remainder, else continue
  case $first in
    ([[:space:]]) trim "$rest"; return;;
  esac

  # Then trim the trailing whitespace, recursing if necessary
  # Split the string into every other character, and the last character
  local last="${str#"${str%?}"}"
  local beginning="${str%?}"
  # If the last character is a space, recurse on the remainder, else we are finished
  case $last in
    ([[:space:]]) trim "$beginning"; return;;
  esac
  # Neither the first nor the last character is a space
  # This is the only recursive call that should set trim_ret, and then the stack should unwind
  trim_ret="$str"
}

press_enter_to_boot () {
  local code="${1:-1}"
  if [ -n "$INTERACTIVE" ] ; then
    get_user_input "Press (enter) to continue booting"
  fi
  exit "$code"
}

get_user_input () {
  debug "func: get_user_input"
  get_user_input_ret=
  printf "\n\n%s\n" "$1"
  # Allow failures here, just treat it as if the user didn't type anything
  read -r get_user_input_ret
}

error () {
  local message="$1"
  printf "[lvm-autosnap] %s\n" "$message" >&2
}

warn () {
  local message="$1"
  if [ -n "${LOG_LEVEL:-2}" ] && [ "${LOG_LEVEL:-2}" -ge 1 ] ; then
    printf "[lvm-autosnap] %s\n" "$message" >&2
  fi
}

info () {
  local message="$1"
  if [ -n "${LOG_LEVEL:-2}" ] && [ "${LOG_LEVEL:-2}" -ge 2 ] ; then
    printf "[lvm-autosnap] %s\n" "$message"
  fi
}

prompt () {
  local message="$1"
  printf "%s\n" "$message"
}

debug () {
  local message="$1"
  if [ -n "${LOG_LEVEL:-2}" ] && [ "${LOG_LEVEL:-2}" -ge 3 ] ; then
    printf "[lvm-autosnap] %s\n" "$message"
  fi
}
