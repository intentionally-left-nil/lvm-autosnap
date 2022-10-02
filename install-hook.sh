#!/usr/bin/bash
build() {
  # mkinitcpio runs everything in the same shell O_o
  # To prevent breaking other scripts (e.g. when running set -f)
  # run our code in a subshell, then propagate the error upwards
  ( 
    set -uf
    export SCRIPT_PATH=/usr/share/lvm-autosnap
    export LVM_SUPPRESS_FD_WARNINGS=1
    # shellcheck source=config.sh
    . "$SCRIPT_PATH/config.sh"

    # shellcheck source=core.sh
    . "$SCRIPT_PATH/core.sh"

    # Validate the .env file is valid, otherwise fail out
    config_set_defaults
    load_config_from_env
    validate_config

    if [ -z "$VALIDATE_CONFIG_RET" ] ; then
      exit 1
    fi
  ) || exit "$?"

  # Once we've validated lvm-autosnap.env
  # the remaining code _must_ be run in the initial shell,
  # or nothing gets actually added to the initramfs

  add_binary /usr/bin/lvm-autosnap
  
  # Add our scripts
  add_file /etc/lvm-autosnap.env
  add_full_dir /usr/share/lvm-autosnap
  add_runscript
}

help() {
  cat <<EOF
This hook creates a lvm snapshot the boot process, before the filesystem is loaded.
Later, if the hook detects that the previous several boots were unsuccessful
it prompts the user to restore from a snapshot.
EOF
}
