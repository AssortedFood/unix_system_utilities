#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

FILE="$1"

# Validate
[[ -f $FILE ]] || { echo "❌ File not found: $FILE"; exit 1; }

# If we have a DISPLAY (and xclip), assume local X session
if [[ -n "${DISPLAY-}" && -x "$(command -v xclip)" ]]; then
  xclip -selection clipboard < "$FILE"
  echo "📋 Copied ‘$FILE’ via xclip"
  exit 0
fi

# On macOS with pbcopy
if [[ "$(uname)" == "Darwin" && -x "$(command -v pbcopy)" ]]; then
  pbcopy < "$FILE"
  echo "📋 Copied ‘$FILE’ via pbcopy"
  exit 0
fi

# Otherwise, try OSC 52
data=$(base64 < "$FILE" | tr -d '\n')
printf '\e]52;c;%s\a' "$data"
echo "📋 Copied ‘$FILE’ via OSC 52"
