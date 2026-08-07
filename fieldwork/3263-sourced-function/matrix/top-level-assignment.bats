#!/usr/bin/env bats

@test "first test executes a sourced top-level assignment" {
    # shellcheck source=./top-level.sh
    source "$BATS_TEST_DIRNAME/top-level.sh"
    [ "$TOP_LEVEL_REPLY" = hello ]
}

@test "second test cannot inherit the first test assignment" {
    [ "$TOP_LEVEL_REPLY" = hello ]
}
