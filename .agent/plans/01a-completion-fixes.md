# Completion Fixes Plan

## Overview

Address remaining issues from the restructuring plan to achieve full completion.

## Issues to Fix

### 1. Add BATS Tests for New Utilities

Create test files following the pattern in `utilities/summarise_project/tests/`:

- `utilities/worktree_add/tests/worktree_add.bats` - test error cases (no branch name, not in git repo, not on default branch)
- `utilities/worktree_remove/tests/worktree_remove.bats` - test error cases (no branch name, not in git repo, worktree doesn't exist)
- `utilities/worktree_remove/tests/completions.bats` - test that completion function is defined and registered

Tests should use setup/teardown with temp directories for git operations.

---

### 2. Fix README.md

Two changes:

1. Add `prompt` to utilities table (it's a sourced utility, note this in description)
2. Remove `sudo` from install command - installer handles sudo internally for deps

---

### 3. Refactor install.sh to Use lib/common.sh

**Problem:** install.sh duplicates colors, logging functions, and platform detection instead of sourcing lib/common.sh.

**Fix:** Source lib/common.sh and remove the duplicated code. Keep only what's unique to install.sh (like `matches_platform()` and `BOLD`).

---

### 4. Simplify Uninstall to Full-Only

**Problem:** Partial uninstall (removing specific utilities) doesn't work - code just warns to edit manually.

**Fix:** Remove the partial uninstall code path entirely. Update help text to clarify uninstall removes everything, and suggest re-running installer to change selection.

---

## Implementation Order

1. Create 3 BATS test files
2. Fix README.md
3. Refactor install.sh to source lib/common.sh
4. Simplify do_uninstall() and show_help()

## Verification

- All test files pass syntax check
- install.sh passes syntax check
- README contains "prompt" in utilities table
- README does not contain "sudo ./install.sh"
- install.sh contains `source.*lib/common.sh`

## Commits

Per `.agent/coding_standards.md`:
- `tests: add BATS tests for worktree utilities`
- `readme: add prompt utility, remove sudo from install`
- `install: use lib/common.sh, simplify uninstall`
