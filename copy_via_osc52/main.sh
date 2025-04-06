#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

FILE="$1"

# Validate
[[ -f $FILE ]] || exit 1

# 1. Local X11 via xclip
if [[ -n "${DISPLAY-}" && -x "$(command -v xclip)" ]]; then
  xclip -selection clipboard < "$FILE"
  exit 0
fi

# 2. macOS via pbcopy
if [[ "$(uname)" == "Darwin" && -x "$(command -v pbcopy)" ]]; then
  pbcopy < "$FILE"
  exit 0
fi

# 3. Fallback: OSC52 escape
data=$(base64 < "$FILE" | tr -d '\n')
printf '\e]52;c;%s\a' "$data"
