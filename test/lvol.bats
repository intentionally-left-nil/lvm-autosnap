#! /usr/bin/env bats
function setup() {
  load 'test_helper/common-setup'
    common_setup
}

@test "lvol_field:empty lvol" {
  lvol_field "" "vg_name"
  assert_equal "$LVOL_FIELD_RET" ""
}

@test "lvol_field:first field" {
  lvol_field "myvg|mylv" "vg_name"
  assert_equal "$LVOL_FIELD_RET" "myvg"
}

@test "lvol_field:second field" {
  lvol_field "myvg|mylv|myuuid" "lv_name"
  assert_equal "$LVOL_FIELD_RET" "mylv"
}

@test "lvol_field:last field" {
  lvol_field "my vg|my lv|my uuid|tags|time|origin|yes it's invalid" "lv_snapshot_invalid"
  assert_equal "$LVOL_FIELD_RET" "yes it's invalid"
}

@test "lvol_field:last field if empty" {
  lvol_field "my vg|my lv|my uuid|tags|time|origin|" "lv_snapshot_invalid"
  assert_equal "$LVOL_FIELD_RET" ""
}

@test "lvol_field:last field if missing" {
  lvol_field "my vg|my lv|my uuid|tags|time|origin" "lv_snapshot_invalid"
  assert_equal "$LVOL_FIELD_RET" ""
}

@test "lvol_field:empty column name" {
  run lvol_field "myvg" ""
  assert_failure
}

@test "lvol_field:wrong column name" {
  run lvol_field "myvg" "missing column name"
  assert_failure
}

@test "lvol_tag:empty lvol" {
  lvol_tag "" "aoeu"
  assert_equal "$LVOL_TAG_RET" ""
}

@test "lvol_tag:lvol without tags" {
  lvol_tag "myvg|mylv|myuuid||" "aoeu"
  assert_equal "$LVOL_TAG_RET" ""
}

@test "lvol_tag:returns first match" {
  lvol_tag "myvg|mylv|myuuid|mykey,mykey:val1,mykey:val2|" "mykey"
  assert_equal "$LVOL_TAG_RET" "val1"
}

@test "lvol_display_name:normal volume" {
  lvol_display_name "my vg|my lv|my uuid|my_tags|5th of November, 1605|||"
  assert_equal "$LVOL_DISPLAY_NAME_RET" "my vg/my lv"
}

@test "lvol_display_name:snapshot" {
  lvol_display_name "my vg|my lv|my uuid|my_tags|5th of November, 1605|root||"
  assert_equal "$LVOL_DISPLAY_NAME_RET" "my vg/my lv (snapshot of root @ 5th of November, 1605)"
}

@test "first_lvol:empty" {
  first_lvol ""
  assert_equal "$FIRST_LVOL_RET" ""
}

@test "first_lvol:first of one lvol" {
  first_lvol "abc"
  assert_equal "$FIRST_LVOL_RET" "abc"
}
@test "first_lvol:first of two lvols" {
  first_lvol "abc
def"
  assert_equal "$FIRST_LVOL_RET" "abc"
}
