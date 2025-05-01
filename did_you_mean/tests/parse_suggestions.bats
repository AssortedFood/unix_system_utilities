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