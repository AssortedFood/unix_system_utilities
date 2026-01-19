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
    echo "Usage: awt <feature/branch-name>"
    exit 1
fi

# Flatten for folder: feature/new-logic -> feature-new-logic
FOLDER_NAME=$(echo "$BRANCH_NAME" | tr '/' '-')

# --- 4. Smart Worktree Location ---
CURRENT_DIR_NAME=$(basename "$REPO_ROOT")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_DIR_NAME" != "$CURRENT_BRANCH" ]; then
    echo "Warning: Directory '$CURRENT_DIR_NAME' doesn't match branch '$CURRENT_BRANCH'"
    echo "Worktrees will be created as siblings (e.g., ../$FOLDER_NAME)"
    read -p "Proceed? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

WORKTREE_BASE="$(dirname "$REPO_ROOT")"
TARGET_DIR="${WORKTREE_BASE}/${FOLDER_NAME}"

# --- 5. Integrity Checks ---
# Ensure we don't overwrite an existing directory
if [ -d "$TARGET_DIR" ]; then
    echo "Error: Worktree folder already exists at $TARGET_DIR"
    exit 1
fi

# Ensure we're on the default branch
if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    echo "Error: Current branch is '$CURRENT_BRANCH', not '$DEFAULT_BRANCH'."
    echo "Switch to $DEFAULT_BRANCH before creating a new worktree."
    exit 1
fi

# --- 6. Execution ---
echo "Updating $DEFAULT_BRANCH branch..."
git pull origin "$DEFAULT_BRANCH" || { echo "Error: Failed to pull latest changes."; exit 1; }

echo "Adding Worktree: $BRANCH_NAME"
git worktree add -b "$BRANCH_NAME" "$TARGET_DIR" || { echo "Error: Failed to create worktree."; exit 1; }

# --- 7. Copy Gitignored Files ---
# Exclusions: node_modules, build artifacts, package manager caches
EXCLUDE_PATTERNS="node_modules|dist|build|\.next|\.nuxt|\.turbo|\.cache|\.parcel-cache|out"

echo "Copying gitignored files..."
git -C "$REPO_ROOT" ls-files --others --ignored --exclude-standard -z | while IFS= read -r -d '' file; do
    # Skip excluded directories (anywhere in path)
    if [[ "$file" =~ (^|/)($EXCLUDE_PATTERNS)/ ]]; then
        continue
    fi

    src_file="${REPO_ROOT}/${file}"
    dest_file="${TARGET_DIR}/${file}"

    # Skip if source doesn't exist (shouldn't happen, but safe)
    [ -f "$src_file" ] || continue

    mkdir -p "$(dirname "$dest_file")"
    cp "$src_file" "$dest_file"
    echo "  Copied: $file"
done

# --- 8. Auto-Detect Package Manager & Install ---
install_dependencies() {
    local dir="$1"
    if [ -f "$dir/package.json" ]; then
        echo "  Installing in: ${dir#$TARGET_DIR/}"
        if [ -f "$dir/bun.lockb" ] || [ -f "$dir/bun.lock" ]; then
            command -v bun >/dev/null || { echo "    Error: bun not found"; return 1; }
            (cd "$dir" && bun install)
        elif [ -f "$dir/pnpm-lock.yaml" ]; then
            command -v pnpm >/dev/null || { echo "    Error: pnpm not found"; return 1; }
            (cd "$dir" && pnpm install --approve-builds)
        elif [ -f "$dir/yarn.lock" ]; then
            command -v yarn >/dev/null || { echo "    Error: yarn not found"; return 1; }
            (cd "$dir" && yarn install)
        elif [ -f "$dir/deno.lock" ]; then
            command -v deno >/dev/null || { echo "    Error: deno not found"; return 1; }
            (cd "$dir" && deno install)
        else
            (cd "$dir" && npm install)
        fi
    fi
}

echo "Installing dependencies..."
# Find and install in directories with package.json
while IFS= read -r -d '' pkg; do
    install_dependencies "$(dirname "$pkg")"
done < <(find "$TARGET_DIR" -name 'package.json' -type f ! -path '*/node_modules/*' -print0)

echo "Ready: $TARGET_DIR"
