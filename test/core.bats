#! /usr/bin/env bats
function setup() {
  load 'test_helper/common-setup'
    common_setup
}

@test "backup:volume not found" {
  MOCK_LVM_CREATE_SNAPSHOT=('aoeu')
  MOCK_LVM_GET_VOLUMES=("")
  CONFIGS="myvg,mylv,10g"
  run backup "1"
  assert_failure
  assert_output "[lvm-autosnap](error) Could not find the newly created snapshot myvg/aoeu"
}

@test "backup:a single volume" {
  MOCK_LVM_CREATE_SNAPSHOT=('my snapshot')
  MOCK_LVM_GET_VOLUMES=("my vg|my snapshot|my uuid|pending:2|time1" "my vg|my snapshot|my uuid|pending:2,group_id:123|time1")
  CONFIGS="myvg,mylv,10g"
  backup "1"
  assert_equal "${MOCK_LVM_CREATE_SNAPSHOT_ARGS[*]}" "myvg/mylv/10g/2/true/"
  assert_equal "$MOCK_LVM_ADD_TAG_LVOL" "my vg|my snapshot|my uuid|pending:2|time1"
  assert_equal "$MOCK_LVM_ADD_TAG_TAG" "group_id:my uuid"
}

@test "backup:two volumes" {
  CONFIGS="myvg,root,10g/myvg,home,20g"
  MOCK_LVM_CREATE_SNAPSHOT=('root snapshot' 'home snapshot')
  MOCK_LVM_GET_VOLUMES=("myvg|root snapshot|root_snapshot_uuid|pending:1|time1" "myvg|root snapshot|root_snapshot_uuid|pending:1,group_id:root_snapshot_uuid
myvg|home snapshot|home_snapshot_uuid|group_id:root_snapshot_uuid")
  backup "0"
  assert_equal "${MOCK_LVM_CREATE_SNAPSHOT_ARGS[*]}" "myvg/root/10g/1/true/ myvg/home/20g/1/false/root_snapshot_uuid"
  assert_equal "$MOCK_LVM_ADD_TAG_LVOL" "myvg|root snapshot|root_snapshot_uuid|pending:1|time1"
  assert_equal "$MOCK_LVM_ADD_TAG_TAG" "group_id:root_snapshot_uuid"
}

@test "restore:device is open" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:0,group_id:25")
  restore
  assert_equal "$RESTORE_RET" ""
}

@test "restore:no group_id" {
  MOCK_LVM_GET_VOLUMES=("" "")
  restore
  assert_equal "$RESTORE_RET" ""
}

@test "restore:user declines confirmation" {
  MOCK_LVM_GET_VOLUMES=("" "my vg|my lv|my uuid|pending:0,group_id:25|time1
my vg2|my lv2|my uuid|pending:0,group_id:26|time2")
  MOCK_GET_USER_INPUT=("1" "no")
  restore
  assert_equal "$RESTORE_RET" ""
}

@test "restore:user restores group 1" {
  MOCK_LVM_GET_VOLUMES=("" "my vg|my lv|my uuid|pending:0,group_id:25|time1
my vg2|my lv2|my uuid|pending:0,group_id:26|time2")
  MOCK_GET_USER_INPUT=("1" "I_HAVE_BACKUPS_ELSEWHERE")
  restore
  assert_equal "$RESTORE_RET" "1"
  assert_equal "$MOCK_LVM_RESTORE_SNAPSHOT_GROUP_ID" "25"
}

@test "restore:user restores group 2" {
  MOCK_LVM_GET_VOLUMES=("" "my vg|my lv|my uuid|pending:0,group_id:25|time1
my vg2|my lv2|my uuid|pending:0,group_id:26|time2")
  MOCK_GET_USER_INPUT=("2" "I_HAVE_BACKUPS_ELSEWHERE")
  restore
  assert_equal "$RESTORE_RET" "1"
  assert_equal "$MOCK_LVM_RESTORE_SNAPSHOT_GROUP_ID" "26"
}

@test "get_group_id_to_restore:no known_good snapshots" {
  MOCK_LVM_GET_VOLUMES=("")
  get_group_id_to_restore
  assert_equal "$GET_GROUP_ID_TO_RESTORE_RET" ""
}

@test "get_group_id_to_restore:user selects no" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:0,group_id:25")
  MOCK_GET_USER_INPUT=("no")
  get_group_id_to_restore
  assert_equal "$GET_GROUP_ID_TO_RESTORE_RET" ""
}

@test "get_group_id_to_restore:user selects 0" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:0,group_id:25|time1
my vg2|my lv2|my uuid|pending:0,group_id:26|time2")
  MOCK_GET_USER_INPUT=("0")
  get_group_id_to_restore
  assert_equal "$GET_GROUP_ID_TO_RESTORE_RET" ""
}

@test "get_group_id_to_restore:user selects 1" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:0,group_id:25|time1
my vg2|my lv2|my uuid|pending:0,group_id:26|time2")
  MOCK_GET_USER_INPUT=("1")
  get_group_id_to_restore
  assert_equal "$GET_GROUP_ID_TO_RESTORE_RET" "25"
}

@test "get_group_id_to_restore:user selects 2" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:0,group_id:25|time1
my vg2|my lv2|my uuid|pending:0,group_id:26|time2")
  MOCK_GET_USER_INPUT=("2")
  get_group_id_to_restore
  assert_equal "$GET_GROUP_ID_TO_RESTORE_RET" "26"
}

@test "get_group_id_to_restore:user selects 3" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:0,group_id:25|time1
my vg2|my lv2|my uuid|pending:0,group_id:26|time2")
  MOCK_GET_USER_INPUT=("3")
  get_group_id_to_restore
  assert_equal "$GET_GROUP_ID_TO_RESTORE_RET" ""
}

@test "remove_old_snapshots:no snapshots to remove when less than MAX_SNAPSHOTS" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:5")
  MAX_SNAPSHOTS=2
  remove_old_snapshots
  assert_equal "${MOCK_LVM_REMOVE_SNAPSHOT_GROUP_ID=not_set}" "not_set"
}

@test "remove_old_snapshots:remove one snapshot when equal to MAX_SNAPSHOTS" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:5,group_id:25" "my vg|my lv|my uuid|pending:5,group_id:25" "")
  MAX_SNAPSHOTS=1
  remove_old_snapshots
  assert_equal "${MOCK_LVM_REMOVE_SNAPSHOT_GROUP_ID=not_set}" "25"
}

@test "remove_old_snapshots:remove two snapshots when greater than MAX_SNAPSHOTS" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:0,group_id:25
my vg2|my lv2|my uuid|pending:5,group_id:26" "my vg|my lv|my uuid|pending:5,group_id:25" "my vg2|my lv2|my uuid|pending:5,group_id:26" "my vg2|my lv2|my uuid|pending:5,group_id:26" "")
  MAX_SNAPSHOTS=1
  remove_old_snapshots
  assert_equal "${MOCK_LVM_REMOVE_SNAPSHOT_GROUP_ID=not_set}" "26"
}

@test "remove_old_snapshot:no snapshots" {
  MOCK_LVM_GET_VOLUMES=("" "")
  remove_old_snapshot
  assert_equal "$REMOVE_OLD_SNAPSHOT_RET" ""
}

@test "remove_old_snapshot:known good snapshot missing group_id" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:0" "my vg2|my lv2|my uuid2|pending:1,group_id:25")
  remove_old_snapshot
  assert_equal "$REMOVE_OLD_SNAPSHOT_RET" "1"
  assert_equal "$MOCK_LVM_REMOVE_SNAPSHOT_GROUP_ID" "25"
}

@test "remove_old_snapshot:missing group_id" {
  MOCK_LVM_GET_VOLUMES=("" "my vg2|my lv2|my uuid2|pending:1")
  remove_old_snapshot
  assert_equal "$REMOVE_OLD_SNAPSHOT_RET" ""
}

@test "root_pending_count:no tags" {
  MOCK_LVM_GET_VOLUMES=
  root_pending_count
  assert_equal "$ROOT_PENDING_COUNT_RET" 0
}

@test "root_pending_count:snapshot missing pending" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|my tags")
  root_pending_count
  assert_equal "$ROOT_PENDING_COUNT_RET" 0

}

@test "root_pending_count:get snapshot tag" {
  MOCK_LVM_GET_VOLUMES=("my vg|my lv|my uuid|pending:5")
  root_pending_count
  assert_equal "$ROOT_PENDING_COUNT_RET" 5
}
