#!/usr/bin/env bash
# tests/helpers.bash

# Create a fresh sandbox, copy script & .summaryignore into it, and cd into it
setup_project() {
  TMP=$(mktemp -d)
  cp "${BATS_TEST_DIRNAME}/../main.sh"      "$TMP"/main.sh
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

# Run the summariser via its shebang
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
  local ROOT="$(pwd)"

  # Fake xclip and pbcopy in PATH
  mkdir -p fakebin
  for cmd in xclip pbcopy; do
    cat > fakebin/$cmd <<EOF
#!/usr/bin/env bash
# write stdin to clipboard.txt
cat > "$ROOT/clipboard.txt"
EOF
    chmod +x fakebin/$cmd
  done

  # Fake OSC52 helper in ../copy_via_osc52
  mkdir -p ../copy_via_osc52
  cat > ../copy_via_osc52/main.sh <<EOF
#!/usr/bin/env bash
# copy the file argument into clipboard.txt
cat "\$1" > "$ROOT/clipboard.txt"
EOF
  chmod +x ../copy_via_osc52/main.sh

  export PATH="$ROOT/fakebin:$PATH"
}
