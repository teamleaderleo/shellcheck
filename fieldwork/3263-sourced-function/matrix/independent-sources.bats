#!/usr/bin/env bats

@test "first test sources the library" {
    # shellcheck source=../lib.sh
    source "$BATS_TEST_DIRNAME/../lib.sh"
    true
}

@test "second test sources independently before calling" {
    # shellcheck source=../lib.sh
    source "$BATS_TEST_DIRNAME/../lib.sh"
    fill_reply hello
    [ "${COMPREPLY[0]}" = hello ]
}
