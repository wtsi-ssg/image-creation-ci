#!/usr/bin/env bats

@test "vi  found in PATH" {
  run which vi
  [ "$status" -eq 0 ]
}
