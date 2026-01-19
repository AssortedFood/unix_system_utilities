#!/usr/bin/env bats
# tests/completions.bats

setup() {
  source "${BATS_TEST_DIRNAME}/helpers.bash"
}

@test "completion function is defined after sourcing" {
  source "$COMPLETIONS_PATH"

  # Check that the function exists
  run type _rwt_completions
  [ "$status" -eq 0 ]
  [[ "$output" == *"function"* ]]
}

@test "completion is registered for rwt command" {
  source "$COMPLETIONS_PATH"

  # Check that complete was called for rwt
  run complete -p rwt
  [ "$status" -eq 0 ]
  [[ "$output" == *"_rwt_completions"* ]]
}

@test "completions.sh passes syntax check" {
  run bash -n "$COMPLETIONS_PATH"
  [ "$status" -eq 0 ]
}
