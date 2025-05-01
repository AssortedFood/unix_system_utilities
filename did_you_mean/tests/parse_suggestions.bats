#!/usr/bin/env bats
# Source the parser stub for tests
if [ -n "$BATS_TEST_DIRNAME" ]; then
  source "$BATS_TEST_DIRNAME/../src/parser.sh"
else
  source src/parser.sh
fi
# Sample suggestion output fixtures
SAMPLE_STD=$'  1) git in package git\n  2) ls in package coreutils\n  3) cat in package coreutils'
SAMPLE_DUP=$'  1) ssh in package dropbear\n  2) ssh in package openssh\n  3) ssh in package openssh'
SAMPLE_WS=$'  1)   git    in package   git   \n  2)  ls  in package    coreutils   '
SAMPLE_NO_PKG=$'  1) foobar\n  2) baz'

@test "parse_suggestions returns success status" {
  # Calling without input should still succeed
  run parse_suggestions
  [ "$status" -eq 0 ]
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
 
@test "parse_suggestions populates PKG array with correct packages for SAMPLE_STD" {
  # Source parser stub
  source "$BATS_TEST_DIRNAME/../src/parser.sh" 2>/dev/null || true
  # Invoke parser with SAMPLE_STD
  parse_suggestions <<EOF
$SAMPLE_STD
EOF
  # Expect packages: git, coreutils, coreutils
  [ "${PKG[0]}" = "git" ]
  [ "${PKG[1]}" = "coreutils" ]
  [ "${PKG[2]}" = "coreutils" ]
}

@test "parse_suggestions trims whitespace for SAMPLE_WS" {
  # Invoke parser with SAMPLE_WS input
  parse_suggestions <<EOF
$SAMPLE_WS
EOF
  # Expect two entries
  [ "${#IDX[@]}" -eq 2 ]
  # Expect trimmed values: no leading/trailing spaces
  [ "${IDX[0]}" = "1" ]
  [ "${IDX[1]}" = "2" ]
  [ "${CMD[0]}" = "git" ]
  [ "${CMD[1]}" = "ls" ]
  [ "${PKG[0]}" = "git" ]
  [ "${PKG[1]}" = "coreutils" ]
}

@test "parse_suggestions preserves duplicate commands for SAMPLE_DUP" {
  parse_suggestions <<EOF
$SAMPLE_DUP
EOF
  # Expect three suggestions
  [ "${#IDX[@]}" -eq 3 ]
  # All commands should be 'ssh'
  [ "${CMD[0]}" = "ssh" ]
  [ "${CMD[1]}" = "ssh" ]
  [ "${CMD[2]}" = "ssh" ]
  # Packages: dropbear, openssh, openssh
  [ "${PKG[0]}" = "dropbear" ]
  [ "${PKG[1]}" = "openssh" ]
  [ "${PKG[2]}" = "openssh" ]
}

@test "parse_suggestions assigns unknown package for SAMPLE_NO_PKG" {
  parse_suggestions <<EOF
$SAMPLE_NO_PKG
EOF
  # Expect two suggestions with unknown packages
  [ "${#PKG[@]}" -eq 2 ]
  [ "${PKG[0]}" = "unknown" ]
  [ "${PKG[1]}" = "unknown" ]
}