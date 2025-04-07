#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ————————————————————————————————————————————————————————————————
# 1. Determine the directory this script lives in
# ————————————————————————————————————————————————————————————————
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_FILE="$SCRIPT_DIR/.profiles"

# ————————————————————————————————————————————————————————————————
# 2. Load profiles (if .profiles exists)
#    Format:   name=port1 port2 port3
#    Comments and blank lines are ignored
# ————————————————————————————————————————————————————————————————
declare -A PROFILES
if [[ -f "$PROFILE_FILE" ]]; then
  while IFS='=' read -r key value; do
    # skip comments or empty lines
    [[ "$key" =~ ^# ]] && continue
    [[ -z "$key" ]]   && continue
    PROFILES["$key"]="$value"
  done < "$PROFILE_FILE"
fi

# ————————————————————————————————————————————————————————————————
# 3. Basic argument check
#    Need at least: profile|port and host
# ————————————————————————————————————————————————————————————————
if [[ "$#" -lt 2 ]]; then
  echo "Usage: $0 [profile|port1 [port2 …]] host"
  echo "Example: $0 profile1 onyx"
  echo "         $0 8888 5432 onyx"
  exit 1
fi

# ————————————————————————————————————————————————————————————————
# 4. Determine ports & host
#    If first arg matches a profile name, use that list
#    Otherwise treat all but last arg as ports
# ————————————————————————————————————————————————————————————————
if [[ -n "${PROFILES[$1]:-}" ]]; then
  # profile shorthand
  ports=(${PROFILES[$1]})
  host="$2"
else
  # explicit ports
  host="${@: -1}"
  ports=("${@:1:$#-1}")
fi

# ————————————————————————————————————————————————————————————————
# 5. Build and run the SSH command
# ————————————————————————————————————————————————————————————————
ssh_command="ssh"
for port in "${ports[@]}"; do
  ssh_command+=" -L ${port}:localhost:${port}"
done
ssh_command+=" ${host}"

echo "Running: $ssh_command ✨"
eval "$ssh_command"
