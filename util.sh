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
    at_index_ret=$(eval "echo \${$i}")
  fi
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
