#!/usr/bin/env bats

# Sample suggestion output fixtures
SAMPLE_STD=$'  1) git in package git\n  2) ls in package coreutils\n  3) cat in package coreutils'
SAMPLE_DUP=$'  1) ssh in package dropbear\n  2) ssh in package openssh\n  3) ssh in package openssh'
SAMPLE_WS=$'  1)   git    in package   git   \n  2)  ls  in package    coreutils   '
SAMPLE_NO_PKG=$'  1) foobar\n  2) baz'

@test "parse_suggestions function invocation fails" {
  run parse_suggestions
  [ "$status" -ne 0 ]
}

@test "parse_suggestions populates IDX array with correct count for SAMPLE_STD" {
  # Source parser stub
  source "$BATS_TEST_DIRNAME/../src/parser.sh" 2>/dev/null || true
  # Invoke parser with SAMPLE_STD input
  parse_suggestions <<EOF
$SAMPLE_STD
EOF
  # Expect three indices parsed
  [ "${#IDX[@]}" -eq 3 ]
}

@test "parse_suggestions populates CMD array with correct commands for SAMPLE_STD" {
  # Source parser stub
  source "$BATS_TEST_DIRNAME/../src/parser.sh" 2>/dev/null || true
  # Invoke parser with SAMPLE_STD
  parse_suggestions <<EOF
$SAMPLE_STD
EOF
  # Expect commands: git, ls, cat
  [ "${CMD[0]}" = "git" ]
  [ "${CMD[1]}" = "ls" ]
  [ "${CMD[2]}" = "cat" ]
}