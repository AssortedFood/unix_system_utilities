#!/usr/bin/env bats

# Integration tests for extractor prototype

# Sample suggestion output fixtures for integration
SAMPLE_STD=$'  1) git in package git\n  2) ls in package coreutils\n  3) cat in package coreutils'
SAMPLE_WS=$'  1)   git    in package   git   \n  2)  ls  in package    coreutils   '

setup() {
  # Prepare combined input file
  printf "%s\n%s\n" "$SAMPLE_STD" "$SAMPLE_WS" > "$BATS_TEST_DIRNAME/input.txt"
}

@test "extract_suggestions without input returns non-zero" {
  run extract_suggestions
  [ "$status" -ne 0 ]
}

@test "generate temp file with SAMPLE_STD + SAMPLE_WS" {
  # The combined file should exist and not be empty
  [ -s "$BATS_TEST_DIRNAME/input.txt" ]
}

@test "extract_suggestions with file input returns non-zero" {
  run extract_suggestions "$BATS_TEST_DIRNAME/input.txt"
  [ "$status" -ne 0 ]
}