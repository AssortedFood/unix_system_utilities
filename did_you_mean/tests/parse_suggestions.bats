#!/usr/bin/env bats

@test "parse_suggestions function invocation fails" {
  run parse_suggestions
  [ "$status" -ne 0 ]
}