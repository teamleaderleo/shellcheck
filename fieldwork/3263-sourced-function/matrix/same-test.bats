#!/usr/bin/env bats

@test "source call and read stay in one test" {
    # shellcheck source=../lib.sh
    source "$BATS_TEST_DIRNAME/../lib.sh"
    fill_reply hello
    [ "${COMPREPLY[0]}" = hello ]
}
