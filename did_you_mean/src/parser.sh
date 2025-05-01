#!/usr/bin/env bash

# Stub parser for dm suggestions
parse_suggestions() {
  # Filter input lines matching suggestion pattern
  local regex='^[[:space:]]*[0-9]+\)'
  # Read matching lines into array for further parsing
  mapfile -t SUGGESTION_LINES < <(grep -E "$regex" || true)
  # Extract suggestion indices into IDX array
  IDX=()
  for line in "${SUGGESTION_LINES[@]}"; do
    # Capture leading number before the closing parenthesis
    local num
    num=$(echo "$line" | sed -E 's/^[[:space:]]*([0-9]+)\).*/\1/')
    IDX+=("$num")
  done
  # Extract command names into CMD array
  CMD=()
  for line in "${SUGGESTION_LINES[@]}"; do
    # Capture the command following the index
    local cmd
    cmd=$(echo "$line" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*([^ ]+).*/\1/')
    CMD+=("$cmd")
  done
  return 0
}