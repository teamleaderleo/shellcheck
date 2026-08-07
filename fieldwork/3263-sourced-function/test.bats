#!/usr/bin/env bats

setup() {
    # shellcheck source=./lib.sh
    source "$BATS_TEST_DIRNAME/lib.sh"
}

@test "first test re-sources lib.sh" {
    # shellcheck source=./lib.sh
    source "$BATS_TEST_DIRNAME/lib.sh"
    true
}

@test "plain mapfile assignment is current-shell" {
    fill_reply hello
    [ "${COMPREPLY[0]}" = hello ]
}
