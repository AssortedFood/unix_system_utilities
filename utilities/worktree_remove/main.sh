#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --- 1. Dynamic Repository Detection ---
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
    echo "Error: Not in a git repository."
    exit 1
fi

# --- 2. Default Branch Detection ---
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$DEFAULT_BRANCH" ]; then
    echo "Error: Could not detect default branch from remote."
    echo "Try running:"
    echo "  git remote set-url origin git@github.com:USER/REPO.git"
    echo "  git remote set-head origin --auto"
    exit 1
fi

# --- 3. Parameter Handling ---
BRANCH_NAME=${1:-}
if [ -z "$BRANCH_NAME" ]; then
    echo "Error: Branch name required."
    echo "Usage: rwt <branch-name>"
    exit 1
fi

# Flatten for folder name
FOLDER_NAME=$(echo "$BRANCH_NAME" | tr '/' '-')

# --- 4. Worktree Base Detection ---
WORKTREE_BASE="$(dirname "$REPO_ROOT")"
TARGET_DIR="${WORKTREE_BASE}/${FOLDER_NAME}"

# --- 5. Safety Checks ---

# Check A: Does the folder even exist?
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Worktree directory not found at $TARGET_DIR"
    exit 1
fi

# Check B: Are there uncommitted changes (dirty working tree)?
if [[ -n $(git -C "$TARGET_DIR" status --porcelain) ]]; then
    echo "Warning: You have uncommitted changes in $FOLDER_NAME."
    echo "Please commit or stash them before removing."
    exit 1
fi

# Check C: Are there unpushed commits?
UNPUSHED_COUNT=0

if git rev-parse "origin/$BRANCH_NAME" >/dev/null 2>&1; then
    # Remote branch exists - check if local is ahead
    UNPUSHED_COUNT=$(git rev-list --count "origin/$BRANCH_NAME..$BRANCH_NAME" 2>/dev/null || echo 0)
else
    # No remote branch - check for commits not in default branch
    UNPUSHED_COUNT=$(git rev-list --count "origin/$DEFAULT_BRANCH..$BRANCH_NAME" 2>/dev/null || echo 0)
fi

if [ "$UNPUSHED_COUNT" -gt 0 ]; then
    echo "Warning: Branch '$BRANCH_NAME' has $UNPUSHED_COUNT unpushed commit(s)."
    echo "Push your changes first or use 'git worktree remove -f' manually."
    exit 1
fi

# --- 6. Execution ---
echo "Removing worktree: $FOLDER_NAME..."
git worktree remove "$TARGET_DIR" || { echo "Error: Failed to remove worktree."; exit 1; }

echo "Cleaning up local branch..."
git pull origin "$DEFAULT_BRANCH" || echo "Warning: Failed to pull latest changes."

# -d only deletes if the branch has been merged into its upstream/HEAD
# This is a final built-in Git safety check.
if git branch -d "$BRANCH_NAME" 2>/dev/null; then
    echo "Successfully removed worktree and deleted branch '$BRANCH_NAME'."
else
    echo "Worktree removed, but branch '$BRANCH_NAME' remains (not fully merged or doesn't exist locally)."
fi
