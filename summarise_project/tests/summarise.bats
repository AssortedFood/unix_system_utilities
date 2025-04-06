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
  > .summaryignore

  run_summary txt
  [ "$status" -eq 0 ]

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

  run grep -q "old" summary.md
  [ "$status" -ne 0 ]
  assert_in_summary "## 📄 \`foo.txt\`"
}

@test "copies summary.md contents into clipboard.txt" {
  create_file a.txt "Alpha"
  create_file b.txt "Beta"
  > .summaryignore

  stub_clipboard

  run_summary txt
  [ "$status" -eq 0 ]

  [ -f clipboard.txt ]
  run diff -u summary.md clipboard.txt
  [ "$status" -eq 0 ]
}
