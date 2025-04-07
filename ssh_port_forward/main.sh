#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ————————————————————————————————————————————————————————————————
# 1. Determine the directory this script lives in
# ————————————————————————————————————————————————————————————————
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_FILE="$SCRIPT_DIR/.profiles"

# ————————————————————————————————————————————————————————————————
# 2. Ensure jq is available
# ————————————————————————————————————————————————————————————————
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

# ————————————————————————————————————————————————————————————————
# 3. Basic argument check
# ————————————————————————————————————————————————————————————————
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 [profile|port1 [port2 …]] host"
  exit 1
fi

first_arg="$1"
host="${@: -1}"

# ————————————————————————————————————————————————————————————————
# 4. Load ports from JSON profile or from args
# ————————————————————————————————————————————————————————————————
if [[ -f "$PROFILE_FILE" ]] && jq -e "has(\"$first_arg\")" "$PROFILE_FILE" >/dev/null; then
  profile="$first_arg"
  mapfile -t ports < <(jq -r ".\"$profile\"[]" "$PROFILE_FILE")
  # one‑line port echo:
  echo -n "Using profile '$profile' with ports:"
  printf ' %s' "${ports[@]}"
  echo
else
  ports=("${@:1:$#-1}")
fi

# ————————————————————————————————————————————————————————————————
# 5. Build & run SSH
# ————————————————————————————————————————————————————————————————
ssh_cmd=(ssh)
for p in "${ports[@]}"; do
  if ! [[ $p =~ ^[0-9]+$ ]]; then
    echo "Error: '$p' is not a valid port." >&2
    exit 1
  fi
  ssh_cmd+=(-L "${p}:localhost:${p}")
done
ssh_cmd+=("$host")

# join and echo on one line
ssh_str=$(printf ' %s' "${ssh_cmd[@]}")
echo "Running:${ssh_str}"

# exec it
"${ssh_cmd[@]}"
