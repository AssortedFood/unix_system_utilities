#!/usr/bin/env bash
# Common functions for unix_system_utilities

# Colors - only set if terminal supports them
if [ -t 1 ]; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  RESET=$(tput sgr0)
else
  RED='' GREEN='' YELLOW='' BLUE='' RESET=''
fi

# Logging functions
log_info() {
  printf "%b\n" "${BLUE}ℹ️  $1${RESET}"
}

log_success() {
  printf "%b\n" "${GREEN}✔️  $1${RESET}"
}

log_warn() {
  printf "%b\n" "${YELLOW}⚠️  $1${RESET}"
}

log_error() {
  printf "%b\n" "${RED}✖️  $1${RESET}" >&2
}

# Platform detection
is_wsl() {
  grep -qi Microsoft /proc/version 2>/dev/null
}

is_termux() {
  [[ -n "${TERMUX_VERSION:-}" ]]
}
