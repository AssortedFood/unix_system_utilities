#!/usr/bin/env bats
# tests/worktree_remove.bats

setup() {
  source "${BATS_TEST_DIRNAME}/helpers.bash"
  setup_git_repo
}

teardown() {
  teardown_git_repo
}

@test "error when no branch name provided" {
  run_rwt
  [ "$status" -ne 0 ]
  [[ "$output" == *"Branch name required"* ]]
}

@test "error when not in git repository" {
  cd /tmp
  mkdir -p not_a_repo
  cd not_a_repo

  run_rwt feature/test
  [ "$status" -ne 0 ]
  [[ "$output" == *"Not in a git repository"* ]]

  rm -rf /tmp/not_a_repo
}

@test "error when default branch cannot be detected" {
  # Remove the symbolic ref
  rm -f .git/refs/remotes/origin/HEAD 2>/dev/null || true
  git symbolic-ref --delete refs/remotes/origin/HEAD 2>/dev/null || true

  run_rwt feature/test
  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not detect default branch"* ]]
}

@test "error when worktree directory does not exist" {
  # Create a fake remote so default branch detection works
  git remote add origin . 2>/dev/null || true
  git fetch origin 2>/dev/null || true
  git symbolic-ref refs/remotes/origin/HEAD refs/heads/main 2>/dev/null || true

  run_rwt feature/nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}
