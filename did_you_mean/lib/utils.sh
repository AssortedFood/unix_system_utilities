#!/usr/bin/env bash

# Utility functions for dm (Did You Mean)

# trim_whitespace: remove leading and trailing whitespace from a string
# Usage: trimmed=$(trim_whitespace "  some text  ")
trim_whitespace() {
  local input="$1"
  # remove leading whitespace
  input="${input#${input%%[![:space:]]*}}"
  # remove trailing whitespace
  input="${input%${input##*[![:space:]]}}"
  printf '%s' "$input"
}