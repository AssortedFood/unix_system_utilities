#!/usr/bin/env bash
# tests/helpers.bash for worktree_add

SCRIPT_PATH="${BATS_TEST_DIRNAME}/../main.sh"

# Create a fresh temp directory and initialize a git repo
setup_git_repo() {
  TMP=$(mktemp -d)
  cd "$TMP"
  git init -b main
  git config user.email "test@test.com"
  git config user.name "Test User"
  echo "initial" > file.txt
  git add file.txt
  git commit -m "Initial commit"
  # Set up fake remote HEAD
  git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main 2>/dev/null || true
}

# Clean up the temp directory
teardown_git_repo() {
  cd /
  rm -rf "$TMP"
}

# Run the worktree_add script
run_awt() {
  run bash "$SCRIPT_PATH" "$@"
}
