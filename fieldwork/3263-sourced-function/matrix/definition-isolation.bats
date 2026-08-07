#!/usr/bin/env bats

@test "first test defines a function locally" {
    first_test_only() {
        printf '%s\n' hello
    }
    [ "$(first_test_only)" = hello ]
}

@test "second test cannot rely on the first test definition" {
    first_test_only
}
