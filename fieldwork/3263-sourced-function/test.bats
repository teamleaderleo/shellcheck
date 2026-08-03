#!/usr/bin/env bats

setup() {
  # shellcheck source=./lib.sh
  source "$BATS_TEST_DIRNAME/lib.sh"
}

@test "first test re-sources lib.sh mid-body" {
  # shellcheck source=./lib.sh
  source "$BATS_TEST_DIRNAME/lib.sh"
  true
}

@test "COMPREPLY is set by a plain mapfile, not a subshell" {
  fill_reply hello
  [ "${COMPREPLY[0]}" = hello ]
}
