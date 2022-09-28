#! /usr/bin/env bats

function setup() {
  load 'test_helper/common-setup'
    _common_setup
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

