#!/usr/bin/env bats

setup() {
    # shellcheck source=./lib-a.sh
    source "$BATS_TEST_DIRNAME/lib-a.sh"
}

@test "first test sources same content through another path" {
    # shellcheck source=./lib-b.sh
    source "$BATS_TEST_DIRNAME/lib-b.sh"
    true
}

@test "later test calls the setup-sourced function" {
    fill_reply hello
    [ "${COMPREPLY[0]}" = hello ]
}
