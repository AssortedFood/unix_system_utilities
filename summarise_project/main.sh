#!/bin/bash

# ──────────────────────────────────────────────────────────────────────────────
# summarise_project: generate a Markdown summary of your project,
# honouring only the .summaryignore in the script directory (gitignore syntax)
# for both tree and fd.
# ──────────────────────────────────────────────────────────────────────────────

# 0. Locate script directory (for ignore file)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IGNORE_FILE="$SCRIPT_DIR/.summaryignore"

# 1. If no extensions provided, we’ll match *all* files
if [ "$#" -eq 0 ]; then
    echo "🔍 No extensions specified; matching all files"
fi

# 2. Prepare output
OUTPUT_FILE="summary.md"
> "$OUTPUT_FILE"
echo "🚀 Starting script…"
echo "📝 Output will be saved to: $OUTPUT_FILE"

# 3. Build ignore pattern for tree from the script‑dir .summaryignore
if [[ -f $IGNORE_FILE ]]; then
    TREE_IGNORES=$(grep -vE '^\s*(#|$)' "$IGNORE_FILE" \
                   | sed 's:/*$::' \
                   | paste -sd '|' -)
else
    TREE_IGNORES="node_modules|.next|venv|dist|build|package-lock.json|.env"
fi

echo "## 📂 Project Directory Structure" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
tree -a -I "$TREE_IGNORES" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 4. Locate fd/fdfind
FD_BIN=$(command -v fd   \
         || command -v fdfind \
         || command -v fd-find \
         || true)
if [[ -z "$FD_BIN" ]]; then
    echo "❌ fd (or fdfind / fd-find) not found; please install fd."
    exit 1
fi

# 4.5. Show what we’re searching for
if [ "$#" -eq 0 ]; then
    echo "🔍 Searching for all files (using $(basename "$FD_BIN"), ignoring $IGNORE_FILE)"
else
    echo "🔍 Searching for extensions: $* (using $(basename "$FD_BIN"), ignoring $IGNORE_FILE)"
fi

# 5. Build fd args for each extension (will be empty if no args)
FD_ARGS=()
for ext in "$@"; do
    FD_ARGS+=( -e "$ext" )
done

# 6. Use fd to list files with only .summaryignore (no VCS ignores)
mapfile -t files < <(
    "$FD_BIN" "${FD_ARGS[@]}" \
      --type f \
      --no-ignore-vcs \
      --ignore-file "$IGNORE_FILE" \
      --hidden \
      --color=never
)

# 7. Process and append each file
file_count=0
for file in "${files[@]}"; do
    ((file_count++))
    echo "📄 Processing: $file"

    echo "## 📄 \`${file#./}\`" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo '```md' >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

# 8. Optionally copy via OSC52 helper
COPY_SCRIPT="$SCRIPT_DIR/../copy_via_osc52/main.sh"
if [[ -x "$COPY_SCRIPT" ]]; then
    bash "$COPY_SCRIPT" "$OUTPUT_FILE"
fi

# 9. Final summary
echo "✅ Processing complete!"
echo "📂 Total files written to summary: $file_count"
echo "📄 Check the output in: $OUTPUT_FILE"
