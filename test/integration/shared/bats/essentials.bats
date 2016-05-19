#!/usr/bin/env bats

@test "Is curl installed?" {
  result=$(dpkg -s curl | grep Status)
  [ "$result" == "Status: install ok installed" ]
}

@test "Is subversion installed?" {
  result=$(dpkg -s subversion | grep Status)
  [ "$result" == "Status: install ok installed" ]
}


