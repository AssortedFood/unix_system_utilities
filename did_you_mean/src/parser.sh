#!/usr/bin/env bash

# Stub parser for dm suggestions
parse_suggestions() {
  # Filter input lines matching suggestion pattern
  local regex='^[[:space:]]*[0-9]+\)'
  # Read matching lines into array for further parsing
  mapfile -t SUGGESTION_LINES < <(grep -E "$regex" || true)
  return 0
}