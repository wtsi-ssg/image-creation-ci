#!/usr/bin/env bats

@test "/data1 is a directory on image" {
  run [ -d /data1 ]
  [ "$status" -eq 0 ]
}
