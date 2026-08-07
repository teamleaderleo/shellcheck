#!/usr/bin/env bats

@test "ordinary function bodies remain analyzed" {
    print_unquoted() {
        printf '%s\n' $1
    }

    print_unquoted "hello world"
}
