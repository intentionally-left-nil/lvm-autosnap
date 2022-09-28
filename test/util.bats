#! /usr/bin/env bats

function setup() {
  load 'test_helper/common-setup'
    common_setup
}

@test "is_number:0" {
    is_number 0
    assert [ -n $IS_NUMBER_RET ]
}

@test "is_number:1" {
    is_number 1
    assert [ -n $IS_NUMBER_RET ]
}

@test "is_number:1234" {
    is_number '1234'
    assert [ -n $IS_NUMBER_RET ]
}

@test "is_number:-1" {
    is_number '-1'
    assert [ -z $IS_NUMBER_RET ]
}
@test "is_number:empty_string" {
    is_number ''
    assert [ -z $IS_NUMBER_RET ]
}

@test "is_number:aoeu" {
    is_number 'aoeu'
    assert [ -z $IS_NUMBER_RET ]
}

@test "increment:0" {
    increment "0"
    assert_equal "$INCREMENT_RET" 1
}

@test "increment:1" {
    increment "1"
    assert_equal "$INCREMENT_RET" 2
}

@test "increment:42" {
    increment "42"
    assert_equal "$INCREMENT_RET" 43
}

@test "increment:empty_string" {
    run increment ""
    assert_failure
}

@test "length:empty" {
    length ""
    assert_equal "$LENGTH_RET" 0
}

@test "length:1 item" {
    length "a"
    assert_equal "$LENGTH_RET" 1
}

@test "length:2 items" {
    length "a b"
    assert_equal "$LENGTH_RET" 2
}

@test "length:3 items with commas" {
    local oldifs_length3_test="$IFS"
    IFS=","
    length "a,,b"
    IFS="$oldifs_length3_test"
    assert_equal "$LENGTH_RET" 3
}

@test "at_index:empty_string,0" {
    at_index "" 0
    assert_equal "$AT_INDEX_RET" ""
}

@test "at_index:empty_string,1" {
    at_index "" 1
    assert_equal "$AT_INDEX_RET" ""
}

@test "at_index:0" {
    at_index "a b c" 0
    assert_equal "$AT_INDEX_RET" "a"
}

@test "at_index:1" {
    at_index "a b c" 1
    assert_equal "$AT_INDEX_RET" "b"
}

@test "at_index:2" {
    at_index "a b c" 2
    assert_equal "$AT_INDEX_RET" "c"
}

@test "at_index:past end" {
    at_index "a b c" 3
    assert_equal "$AT_INDEX_RET" ""
}

@test "at_index:1 with commas" {
    local oldifs_length3_test="$IFS"
    IFS=","
    at_index "a a,b,c" 1
    IFS="$oldifs_length3_test"
    assert_equal "$AT_INDEX_RET" "b"
}

@test "header_index:empty_string,0" {
    run header_index "" 0
    assert_failure
}

@test "header_index:a" {
    header_index "a,b,c" "a"
    assert_equal "$HEADER_INDEX_RET" 0
    assert_ifs
}

@test "header_index:b" {
    header_index "a,b,c" "b"
    assert_equal "$HEADER_INDEX_RET" 1
    assert_ifs
}

@test "header_index:c" {
    header_index "a,b,c" "c"
    assert_equal "$HEADER_INDEX_RET" 2
    assert_ifs
}

@test "header_index:missing" {
    run header_index "a,b,c" "missing"
    assert_failure
}

@test "field_by_header: col0 with commas" {
    field_by_header "val0,val1,val2" "col0,col1,col2" "col0" "," 
    assert_equal "$FIELD_BY_HEADER_RET" "val0"
    assert_ifs
}

@test "field_by_header: col1 with commas" {
    field_by_header "val0,val1,val2" "col0,col1,col2" "col1" "," 
    assert_equal "$FIELD_BY_HEADER_RET" "val1"
    assert_ifs
}

@test "field_by_header: col2 with commas" {
    field_by_header "val0,val1,val2" "col0,col1,col2" "col2" "," 
    assert_equal "$FIELD_BY_HEADER_RET" "val2"
    assert_ifs
}

@test "field_by_header: col2 with spaces" {
    field_by_header "val0 val1 val2" "col0,col1,col2" "col2" " " 
    assert_equal "$FIELD_BY_HEADER_RET" "val2"
    assert_ifs
}

@test "field_by_header: empty cols" {
    run field_by_header "val0,val1,val2" "" "" " " 
    assert_failure
}

@test "field_by_header: missing col" {
    run field_by_header "val0,val1,val2" "col0,col1" "col" "," 
    assert_failure
}

@test "field_by_header: empty if not enough vals" {
    field_by_header "val0,val1" "col0,col1,col2" "col2" "," 
    assert_equal "$FIELD_BY_HEADER_RET" ""
    assert_ifs
}

@test "trim:empty string" {
    trim ""
    assert_equal "$TRIM_RET" ""
}

@test "trim:a" {
    trim "a"
    assert_equal "$TRIM_RET" "a"
}

@test "trim:a plus space" {
    trim "a "
    assert_equal "$TRIM_RET" "a"
}

@test "trim:space plus a" {
    trim " a"
    assert_equal "$TRIM_RET" "a"
}

@test "trim:space plus a plus space" {
    trim " a "
    assert_equal "$TRIM_RET" "a"
}

@test "trim: space ab space space cd space space" {
    trim " ab  cd  "
    assert_equal "$TRIM_RET" "ab  cd"
}

@test "trim:whitespaces" {
    trim "   "
    assert_equal "$TRIM_RET" ""
}

@test "trim:no spaces" {
    trim "abcde"
    assert_equal "$TRIM_RET" "abcde"
}

@test "trim:spaces only in the middle" {
    trim "abc de"
    assert_equal "$TRIM_RET" "abc de"
}

@test "press_enter_to_boot" {
    run press_enter_to_boot
    assert_failure
}

@test "print error when log_level is 0" {
    LOG_LEVEL=0
    run error "aoeu"
    assert_output "[lvm-autosnap](error) aoeu"
}

@test "no warnings when log_level is 0" {
    LOG_LEVEL=0
    run warn "aoeu"
    assert_equal "$output" ""
}

@test "prints error when log_level is unset" {
    unset LOG_LEVEL
    run error "aoeu"
    assert_output "[lvm-autosnap](error) aoeu"
}


@test "prints warn when log_level is 1" {
    LOG_LEVEL=1
    run warn "aoeu"
    assert_output "[lvm-autosnap](warn) aoeu"
}

@test "no messages when log_level is empty" {
    LOG_LEVEL=
    run warn "aoeu"
    assert_equal "$output" ""
}

@test "no messages when log_level is unset" {
    unset LOG_LEVEL
    run warn "aoeu"
    assert_equal "$output" ""
}

@test "no info when log_level is 1" {
    LOG_LEVEL=1
    run info "aoeu"
    assert_equal "$output" ""
}

@test "prints info when log_level is 2" {
    LOG_LEVEL=2
    run info "aoeu"
    assert_output "[lvm-autosnap](info) aoeu"
}

@test "no info messages when log_level is unset" {
    unset LOG_LEVEL
    run info "aoeu"
    assert_equal "$output" ""
}

@test "no info when log_level is empty" {
    LOG_LEVEL=
    run info "aoeu"
    assert_equal "$output" ""
}

@test "no debug messages when log_level is unset" {
    unset LOG_LEVEL
    run debug "aoeu"
    assert_equal "$output" ""
}

@test "no debug messages when log_level is empty" {
    LOG_LEVEL=
    run debug "aoeu"
    assert_equal "$output" ""
}

@test "no debug messages when log_level is 2" {
    LOG_LEVEL=2
    run debug "aoeu"
    assert_equal "$output" ""
}

@test "debug messages when log_level is 3" {
    LOG_LEVEL=3
    run debug "aoeu"
    assert_output "[lvm-autosnap](debug) aoeu"
}

@test "debug messages when log_level is 4" {
    LOG_LEVEL=4
    run debug "aoeu"
    assert_output "[lvm-autosnap](debug) aoeu"
}

@test "prompt aoeu" {
    run prompt "aoeu"
    assert_output "aoeu"
}
