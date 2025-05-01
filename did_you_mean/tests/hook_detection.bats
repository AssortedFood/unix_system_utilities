#!/usr/bin/env bats

# Cleanup sentinel file before each test
setup() {
  rm -f /tmp/dm_hook_called
}

@test "hook invocation test stub" {
  # Invoke a non-existent command, redirect stderr to suppress error
  foo123 2>/dev/null
  # Assert that the hook wrote its sentinel file
  [ -f /tmp/dm_hook_called ]
}
