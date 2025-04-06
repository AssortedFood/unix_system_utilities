#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Configuration: map each alias to its script (path is relative to repo root)
# ──────────────────────────────────────────────────────────────────────────────
ALIASES=(
  "copy:copy_via_osc52/main.sh"
  "sp:summarise_project/main.sh"
)

# ──────────────────────────────────────────────────────────────────────────────
# No need to touch anything below here
# ──────────────────────────────────────────────────────────────────────────────

# 1. Locate repo root (where this script lives)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Prepare targets
TARGET="$HOME/.bash_aliases"
RC="$HOME/.bashrc"
touch "$TARGET"

# 3. Collect status messages for later
declare -a MESSAGES

# 4. Make each script executable
for mapping in "${ALIASES[@]}"; do
  IFS=":" read -r name relpath <<< "$mapping"
  script_path="$REPO_ROOT/$relpath"
  if [[ -f "$script_path" ]]; then
    chmod +x "$script_path"
    MESSAGES+=( "✔️  Made \`$relpath\` executable" )
  else
    MESSAGES+=( "⚠️  Script not found: \`$relpath\`" )
  fi
done

# 5. Add aliases to ~/.bash_aliases if not already present
HEADER="# ─── Project aliases for ${REPO_ROOT} ───"
if ! grep -Fq "$HEADER" "$TARGET"; then
  {
    echo
    echo "$HEADER"
    for mapping in "${ALIASES[@]}"; do
      IFS=":" read -r name relpath <<< "$mapping"
      echo "alias $name=\"$REPO_ROOT/$relpath\""
    done
    echo "# ────────────────────────────────────────────────────────────────"
  } >> "$TARGET"
  MESSAGES+=( "✔️  Added project aliases to \`$TARGET\`" )
else
  MESSAGES+=( "ℹ️  Project aliases already present in \`$TARGET\`" )
fi

# 6. Ensure ~/.bash_aliases is sourced from ~/.bashrc
if ! grep -Fq "if [ -f ~/.bash_aliases ]" "$RC"; then
  cat <<'EOF' >> "$RC"

# Load user aliases if present
if [ -f ~/.bash_aliases ]; then
  source ~/.bash_aliases
fi
EOF
  MESSAGES+=( "✔️  Ensured \`~/.bash_aliases\` is sourced from \`~/.bashrc\`" )
else
  MESSAGES+=( "ℹ️  \`~/.bash_aliases\` already sourced in \`~/.bashrc\`" )
fi

# 7. Source the updated ~/.bashrc so aliases take effect now
#    (you may still need to open a new shell to get them everywhere)
source "$RC"

# 8. Finally, print out all our messages
for msg in "${MESSAGES[@]}"; do
  echo -e "$msg"
done
echo -e "🎉  Installation complete! You can now use your new aliases in this shell."
