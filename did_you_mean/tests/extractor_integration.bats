#!/usr/bin/env bats

# Integration tests for extractor prototype
@test "extract_suggestions without input returns non-zero" {
  run extract_suggestions
  [ "$status" -ne 0 ]
}