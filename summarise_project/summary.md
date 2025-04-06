## 📂 Project Directory Structure
```
.
├── main.sh
└── tests
    ├── helpers.bash
    └── summarise.bats

2 directories, 3 files
```

## 📄 `main.sh`

```bash
#!/bin/bash

# ──────────────────────────────────────────────────────────────────────────────
# summarise_project: generate a Markdown summary of your project,
# honouring .summaryignore (gitignore syntax) for both tree and fd.
# ──────────────────────────────────────────────────────────────────────────────

# 1. Ensure at least one file extension is provided
if [ "$#" -eq 0 ]; then
    echo "❌ Usage: $0 <ext1> <ext2> …"
    exit 1
fi

# 2. Prepare output
OUTPUT_FILE="summary.md"
> "$OUTPUT_FILE"
echo "🚀 Starting script…"
echo "📝 Output will be saved to: $OUTPUT_FILE"

# 3. Build ignore pattern for tree
if [[ -f .summaryignore ]]; then
    TREE_IGNORES=$(grep -vE '^\s*(#|$)' .summaryignore \
                   | sed 's:/*$::' \
                   | paste -sd '|' -)
else
    TREE_IGNORES="node_modules|.next|venv|dist|build|package-lock.json|.env"
fi

echo "## 📂 Project Directory Structure" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
tree -I "$TREE_IGNORES" >> "$OUTPUT_FILE"
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

echo "🔍 Searching for extensions: $* (using $(basename "$FD_BIN"), ignoring .summaryignore)"

# 5. Build fd args for each extension
FD_ARGS=()
for ext in "$@"; do
    FD_ARGS+=( -e "$ext" )
done

# 6. Use fd to list files
mapfile -t files < <(
    "$FD_BIN" "${FD_ARGS[@]}" \
      --type f \
      --ignore-file .summaryignore \
      --color=never
)

# 7. Process and append each file
file_count=0
for file in "${files[@]}"; do
    ((file_count++))
    echo "📄 Processing: $file"

    echo "## 📄 \`${file#./}\`" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo '```bash' >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

# 8. Optionally copy via OSC52 if helper exists in ../copy_via_osc52
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COPY_SCRIPT="$SCRIPT_DIR/../copy_via_osc52/main.sh"
if [[ -x "$COPY_SCRIPT" ]]; then
    # Invoke helper with the summary file as its single argument
    bash "$COPY_SCRIPT" "$OUTPUT_FILE"
fi

# 9. Final summary
echo "✅ Processing complete!"
echo "📂 Total files written to summary: $file_count"
echo "📄 Check the output in: $OUTPUT_FILE"
```

## 📄 `tests/helpers.bash`

```bash
#!/usr/bin/env bash
# tests/helpers.bash

# Create a fresh sandbox, copy script & ignore file, and cd into it
setup_project() {
  TMP=$(mktemp -d)
  cp "${BATS_TEST_DIRNAME}/../main.sh" "$TMP"/main.sh
  cp "${BATS_TEST_DIRNAME}/../.summaryignore" "$TMP"/.summaryignore
  chmod +x "$TMP"/main.sh
  cd "$TMP"
}

# Clean up the sandbox
teardown_project() {
  rm -rf "$TMP"
}

# Create a file (and any parent dirs) with given content
create_file() {
  local path="$1" content="${2:-}"
  mkdir -p "$(dirname "$path")"
  printf "%s\n" "$content" > "$path"
}

# Run the summariser via its shebang (so ./main.sh uses absolute bash)
run_summary() {
  run ./main.sh "$@"
}

# Write patterns to .summaryignore (one per line)
write_ignore() {
  printf "%s\n" "$@" > .summaryignore
}

# Assert summary.md contains a string
assert_in_summary() {
  grep -q "$1" summary.md
}

# Assert summary.md does not contain a string
assert_not_in_summary() {
  ! grep -q "$1" summary.md
}

# Run with fd missing by clearing PATH but invoking via shebang
run_without_fd() {
  PATH="" run ./main.sh "$@"
}


# Assert stdout contains a substring
assert_stdout_contains() {
  [[ "$output" == *"$1"* ]]
}

# Stub out all clipboard backends so they dump into clipboard.txt
stub_clipboard() {
  # 1) Fake xclip in PATH
  mkdir -p fakebin
  cat > fakebin/xclip <<'EOF'
#!/usr/bin/env bash
# read stdin into clipboard.txt
cat > clipboard.txt
EOF
  chmod +x fakebin/xclip

  # 2) Fake pbcopy in PATH
  cat > fakebin/pbcopy <<'EOF'
#!/usr/bin/env bash
# read stdin into clipboard.txt
cat > clipboard.txt
EOF
  chmod +x fakebin/pbcopy

  # 3) Fake OSC52 helper in ../copy_via_osc52 (one level up from main.sh)
  mkdir -p ../copy_via_osc52
  cat > ../copy_via_osc52/main.sh <<'EOF'
#!/usr/bin/env bash
# copy the file argument into clipboard.txt
cat "\$1" > clipboard.txt
EOF
  chmod +x ../copy_via_osc52/main.sh

  # Prepend our fakebin so xclip/pbcopy are found first
  export PATH="$(pwd)/fakebin:$PATH"
}
```

## 📄 `tests/summarise.bats`

```bash
#!/usr/bin/env bats
# tests/summarise.bats

setup() {
  source "${BATS_TEST_DIRNAME}/helpers.bash"
  setup_project
}

teardown() {
  teardown_project
}

@test "usage with no arguments" {
  run ./main.sh
  [ "$status" -ne 0 ]
  assert_stdout_contains "Usage:"
}

@test "basic functionality includes .txt files" {
  create_file 1.txt "foo"
  create_file 2.txt "bar"
  > .summaryignore

  run_summary txt
  [ "$status" -eq 0 ]

  assert_in_summary "## 📄 \`1.txt\`"
  assert_in_summary "foo"
  assert_in_summary "## 📄 \`2.txt\`"
  assert_in_summary "bar"
}

@test "multiple extensions" {
  create_file a.py "print('hello')"
  create_file b.js "console.log('hi')"
  create_file c.txt "text"
  > .summaryignore

  run_summary py js
  [ "$status" -eq 0 ]

  assert_in_summary "## 📄 \`a.py\`"
  assert_in_summary "## 📄 \`b.js\`"
  assert_not_in_summary "## 📄 \`c.txt\`"
}

@test "empty .summaryignore ignores nothing" {
  mkdir -p node_modules
  create_file node_modules/foo.txt "secret"
  create_file foo.txt "public"
  > .summaryignore   # empty file

  run_summary txt
  [ "$status" -eq 0 ]

  # Both foo.txt and node_modules/foo.txt should appear
  assert_in_summary "## 📄 \`foo.txt\`"
  assert_in_summary "## 📄 \`node_modules/foo.txt\`"
}

@test "ignore specific file" {
  create_file a.txt "A"
  create_file b.txt "B"
  write_ignore b.txt

  run_summary txt
  [ "$status" -eq 0 ]

  assert_in_summary "## 📄 \`a.txt\`"
  assert_not_in_summary "## 📄 \`b.txt\`"
}

@test "ignore specific directory" {
  mkdir -p secret
  create_file secret/x.txt "hidden"
  create_file visible.txt "visible"
  write_ignore secret/

  run_summary txt
  [ "$status" -eq 0 ]

  assert_in_summary "## 📄 \`visible.txt\`"
  assert_not_in_summary "## 📄 \`secret/x.txt\`"
}

@test "comments and blank lines in .summaryignore" {
  write_ignore "# comment" "" "a.txt"
  create_file a.txt "A"
  create_file b.txt "B"

  run_summary txt
  [ "$status" -eq 0 ]

  assert_not_in_summary "## 📄 \`a.txt\`"
  assert_in_summary     "## 📄 \`b.txt\`"
}

@test "error when fd is missing" {
  create_file a.txt "A"
  > .summaryignore

  run_without_fd txt
  [ "$status" -ne 0 ]
  assert_stdout_contains "❌ fd (or fdfind / fd-find) not found"
}

@test "existing summary.md is overwritten" {
  create_file foo.txt "foo"
  echo "old" > summary.md
  > .summaryignore

  run_summary txt
  [ "$status" -eq 0 ]

  # The old content should be gone, new heading present
  run grep -q "old" summary.md
  [ "$status" -ne 0 ]
  assert_in_summary "## 📄 \`foo.txt\`"
}

@test "copies summary.md contents into clipboard.txt" {
  # Arrange
  create_file a.txt "Alpha"
  create_file b.txt "Beta"
  > .summaryignore     # ignore nothing

  stub_clipboard      # install fake xclip, pbcopy and OSC52 helper

  # Act
  run_summary txt
  [ "$status" -eq 0 ]

  # DEBUG (optional): show both files
  echo "---- summary.md ----";  cat summary.md
  echo "---- clipboard.txt ----";  cat clipboard.txt

  # Assert: clipboard.txt exists and matches summary.md exactly
  [ -f clipboard.txt ]
  run diff -u summary.md clipboard.txt
  [ "$status" -eq 0 ]
}
```

