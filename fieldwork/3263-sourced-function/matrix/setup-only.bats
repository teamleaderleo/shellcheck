#!/usr/bin/env bats

setup() {
    # shellcheck source=../lib.sh
    source "$BATS_TEST_DIRNAME/../lib.sh"
}

@test "first test does not re-source the library" {
    true
}

@test "later test calls the setup-sourced function" {
    fill_reply hello
    [ "${COMPREPLY[0]}" = hello ]
}
