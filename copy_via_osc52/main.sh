#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if [ "$#" -ne 1 ]; then
    echo "❌ Usage: $0 <file-to-copy>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "❌ File not found: $FILE"
    exit 1
fi

# Read, base64‑encode, strip newlines
data=$(base64 < "$FILE" | tr -d '\n')

# Send OSC 52 sequence: ESC ] 52 ; c ; <base64-data> BEL
printf '\e]52;c;%s\a' "$data"
