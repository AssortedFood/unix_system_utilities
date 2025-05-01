#!/usr/bin/env bats

# Source the hook stub to intercept missing commands
if [ -n "$BATS_TEST_DIRNAME" ]; then
  source "$BATS_TEST_DIRNAME/../src/hook.sh"
else
  source src/hook.sh
fi

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
