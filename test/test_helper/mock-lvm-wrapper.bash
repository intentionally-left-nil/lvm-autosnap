lvm_create_snapshot () {
  LVM_CREATE_SNAPSHOT_RET="${MOCK_LVM_CREATE_SNAPSHOT[0]}"
  MOCK_LVM_CREATE_SNAPSHOT=("${MOCK_LVM_CREATE_SNAPSHOT[@]:1}")

  if [ -z "${MOCK_LVM_CREATE_SNAPSHOT_ARGS:-}" ] ; then
    MOCK_LVM_CREATE_SNAPSHOT_ARGS=("$1/$2/$3/$4/$5/${6:-}")
  else
    MOCK_LVM_CREATE_SNAPSHOT_ARGS+=("$1/$2/$3/$4/$5/${6:-}")
  fi
}

lvm_get_volumes () {
  LVM_GET_VOLUMES_RET="${MOCK_LVM_GET_VOLUMES[0]}"
  MOCK_LVM_GET_VOLUMES=("${MOCK_LVM_GET_VOLUMES[@]:1}")
}

lvm_remove_snapshot_group () {
  MOCK_LVM_REMOVE_SNAPSHOT_GROUP_ID="$1"
  true
}

lvm_restore_snapshot_group () {
  MOCK_LVM_RESTORE_SNAPSHOT_GROUP_ID="$1"
  true
}

lvm_add_tag () {
  MOCK_LVM_ADD_TAG_LVOL="$1"
  MOCK_LVM_ADD_TAG_TAG="$2"
  true
}

lvm_del_tag () {
  true
}

lvm_del_tags_from_all () {
  true
}

get_user_input () {
  GET_USER_INPUT_RET="${MOCK_GET_USER_INPUT[0]}"
  MOCK_GET_USER_INPUT=("${MOCK_GET_USER_INPUT[@]:1}")
}
