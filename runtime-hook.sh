#! /usr/bin/ash
# shellcheck shell=dash

# N.B this is run as subshell using () rather than {} because
# 1) We don't want to affect the rest of the runtime hooks and
# 2) We never want to take down init if our script fails
run_hook() (
  set -uf
  SCRIPT_PATH="/usr/share/lvm-autosnap"
  INTERACTIVE=1
  # shellcheck source=core.sh
  . "$SCRIPT_PATH/core.sh"
  main
)
