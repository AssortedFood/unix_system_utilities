#!/usr/bin/env bash

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/utils.sh"

# Stub parser for dm suggestions
parse_suggestions() {
  # Filter input lines matching suggestion pattern
  local regex='^[[:space:]]*[0-9]+\)'
  # Read matching lines into array for further parsing
  mapfile -t SUGGESTION_LINES < <(rg "$regex" || true)
  # Extract suggestion indices into IDX array
  IDX=()
  for line in "${SUGGESTION_LINES[@]}"; do
    # Capture leading number before the closing parenthesis
    local num
    # Trim whitespace from extracted index
    num_raw=$(echo "$line" | sed -E 's/^[[:space:]]*([0-9]+)\).*/\1/')
    num=$(trim_whitespace "$num_raw")
    IDX+=("$num")
  done
  # Extract command names into CMD array
  CMD=()
  for line in "${SUGGESTION_LINES[@]}"; do
    # Capture the command following the index
    local cmd
    # Trim whitespace from extracted command
    cmd_raw=$(echo "$line" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*([^ ]+).*/\1/')
    cmd=$(trim_whitespace "$cmd_raw")
    CMD+=("$cmd")
  done
  # Extract package names into PKG array, defaulting to 'unknown'
  PKG=()
  for line in "${SUGGESTION_LINES[@]}"; do
    local pkg_raw pkg
    if echo "$line" | rg -q 'in package'; then
      # Capture package name after 'in package'
      pkg_raw=$(echo "$line" | sed -E 's/.*in package[[:space:]]*([^ ]+).*/\1/')
    else
      pkg_raw="unknown"
    fi
    # Trim whitespace from extracted package
    pkg=$(trim_whitespace "$pkg_raw")
    PKG+=("$pkg")
  done
  return 0
}