# PLAN

## 1. Hook Detection

1. [ ] **Write Failing Hook Invocation Test**  
   - [x] 1.1. Create test directory if missing (`mkdir -p tests`). **Depends on:** _none_
   - [x] 1.2. Create Bats test file `tests/hook_detection.bats`. **Depends on:** 1.1  
   - [x] 1.3. Add test header and boilerplate to `hook_detection.bats`. **Depends on:** 1.2  
   - [x] 1.4. Ensure test runs and fails before any implementation. **Depends on:** 1.2, 1.3

2. [ ] **Simulate Fake Command & Sentinel Assertion**  
   - [x] 2.1. In the test, run `foo123` and redirect stderr. **Depends on:** 1.4  
   - [x] 2.2. Add assertion that `/tmp/dm_hook_called` file exists. **Depends on:** 2.1  
   - [x] 2.3. Add cleanup step in `setup()` to remove `/tmp/dm_hook_called`. **Depends on:** 2.1

3. [ ] **Implement Minimal Hook Stub**  
   - [x] 3.1. Create `src/hook.sh` defining `command_not_found_handle()` that writes `"DM_HOOK"` into `/tmp/dm_hook_called`. **Depends on:** 1.4  
   - [x] 3.2. Source `src/hook.sh` at top of `tests/hook_detection.bats`. **Depends on:** 3.1, 2.3  
   - [x] 3.3. Run Bats; confirm sentinel assertion passes. **Depends on:** 2.2, 3.2

4. [ ] **Refactor Hook Setup**  
   - [x] 4.1. Ensure all hook logic lives in `src/hook.sh`. **Depends on:** 3.1  
   - [x] 4.2. Update `dm.sh` and `install.sh` to `source src/hook.sh`. **Depends on:** 4.1  
   - [x] 4.3. Re-run hook tests to confirm no regressions. **Depends on:** 4.2, 3.3

---

## 2. Suggestion Parsing

1. [ ] **Write Failing Unit Tests for Parser**  
   - [x] 1.1. Create `tests/parse_suggestions.bats` with boilerplate. **Depends on:** 1.4 (from section 1)  
   - [x] 1.2. Stub call to `parse_suggestions()` and assert failure. **Depends on:** 1.1

2. [ ] **Define Sample Outputs**  
   - [x] 2.1. Add variables holding SAMPLE_STD, SAMPLE_DUP, SAMPLE_WS, SAMPLE_NO_PKG. **Depends on:** 2.1.1

3. [ ] **Assert Array Population**  
   - [x] 3.1. Write test asserting `${#IDX[@]}` equals expected. **Depends on:** 2.2  
   - [x] 3.2. Write test asserting `CMD` array matches expected commands. **Depends on:** 3.1  
   - [x] 3.3. Write test asserting `PKG` array matches expected packages or “unknown”. **Depends on:** 3.1

4. [ ] **Implement Basic Parser Function**  
   - [x] 4.1. Create `src/parser.sh` with stub `parse_suggestions()`. **Depends on:** 2.2  
   - [x] 4.2. Grep lines matching `^\s*[0-9]+\)` in the stub. **Depends on:** 4.1  
   - [x] 4.3. Populate `IDX`, `CMD`, `PKG` arrays in stages:  
     - [x] 4.3.1. Extract indices into `IDX`. **Depends on:** 4.2  
     - [x] 4.3.2. Extract command names into `CMD`. **Depends on:** 4.2  
     - [x] 4.3.3. Extract package names into `PKG`. **Depends on:** 4.2  
   - [x] 4.4. Source `parser.sh` in tests and confirm basic assertions pass. **Depends on:** 4.3.1, 4.3.2, 4.3.3

5. [ ] **Trim Whitespace Handling**  
   - [x] 5.1. Write test for SAMPLE_WS expecting no leading/trailing spaces. **Depends on:** 2.2, 4.4  
   - [x] 5.2. Implement `trim_whitespace()` in `lib/utils.sh`. **Depends on:** 5.1  
   - [x] 5.3. Integrate `trim_whitespace` into index/command/package extraction. **Depends on:** 5.2  
   - [x] 5.4. Confirm SAMPLE_WS test passes. **Depends on:** 5.3

6. [ ] **Duplicate Command Handling**  
   - [x] 6.1. Write test for SAMPLE_DUP expecting both entries preserved. **Depends on:** 2.2, 4.4  
   - [x] 6.2. Decide policy: keep duplicates as separate suggestions. **Depends on:** 6.1  
   - [x] 6.3. Implement duplicate handler in parser:  
     - [x] 6.3.1. Detect duplicate command names in `CMD`. **Depends on:** 6.2  
     - [x] 6.3.2. Allow duplicates by keeping each entry distinct. **Depends on:** 6.3.1  
   - [x] 6.4. Verify SAMPLE_DUP test passes. **Depends on:** 6.3.2

7. [ ] **Missing Package Handling**  
   - [x] 7.1. Write test for SAMPLE_NO_PKG expecting `PKG[i]="unknown"`. **Depends on:** 2.2, 4.4  
   - [x] 7.2. Implement fallback in parser: if package field empty, assign “unknown.” **Depends on:** 7.1  
   - [x] 7.3. Verify SAMPLE_NO_PKG test passes. **Depends on:** 7.2

8. [x] **Refactor & Verify**  
   - [x] 8.1. Move trimming & duplicate helpers to `lib/utils.sh`. **Depends on:** 5.2, 6.3.2  
   - [x] 8.2. Ensure `parser.sh` sources `utils.sh`. **Depends on:** 8.1  
   - [x] 8.3. Run all parser tests; confirm green. **Depends on:** 8.2

---

## 3. Suggestion Extractor Prototype

1. [ ] **Write Failing Integration Tests**  
   - [x] 1.1. Create `tests/extractor_integration.bats`. **Depends on:** 8.3  
   - [x] 1.2. Stub call to `extract_suggestions` with empty input → expect non-zero exit. **Depends on:** 1.1

2. [ ] **Feed Captured Output & Assert Structure**  
   - [x] 2.1. Generate temp file with SAMPLE_STD + SAMPLE_WS. **Depends on:** 2.2  
   - [x] 2.2. In test, call `extract_suggestions temp.txt`. **Depends on:** 1.2  
   - [x] 2.3. Assert output contains valid `export IDX=(…)` lines. **Depends on:** 2.2

3. [ ] **Implement Extraction Logic**  
   - [ ] 3.1. Read input source:  
     - [x] 3.1.1. If first arg is file path, read from file. **Depends on:** 2.2  
     - [x] 3.1.2. Otherwise, read from STDIN. **Depends on:** 3.1.1  
   - [ ] 3.2. Source `src/parser.sh` and call `parse_suggestions()`. **Depends on:** 4.4  
   - [ ] 3.3. Emit arrays:  
     - [ ] 3.3.1. `export IDX=(…)`. **Depends on:** 3.2  
     - [ ] 3.3.2. `export CMD=(…)`. **Depends on:** 3.2  
     - [ ] 3.3.3. `export PKG=(…)`. **Depends on:** 3.2

4. [ ] **Decide Data Format**  
   - [ ] 4.1. Check for `jq` availability in Termux. **Depends on:** 1.4  
   - [ ] 4.2. Choose Bash-array format for minimal dependencies. **Depends on:** 4.1  
   - [ ] 4.3. Document choice in `docs/format.md`. **Depends on:** 4.2

5. [ ] **JSON Serializer (if chosen)**  
   - [ ] 5.1. Write `src/json.sh` with `to_json_array()`. **Depends on:** 4.2  
   - [ ] 5.2. Create `tests/json_serializer.bats` asserting valid JSON. **Depends on:** 5.1  
   - [ ] 5.3. Integrate `to_json_array()` into `extract_suggestions()` if JSON path. **Depends on:** 5.2

6. [ ] **Ensure Global Visibility (if arrays chosen)**  
   - [ ] 6.1. Write `tests/extractor_global.bats` to source extractor output and read arrays. **Depends on:** 3.3.1, 3.3.2, 3.3.3  
   - [ ] 6.2. Implement `export IDX CMD PKG` within `extract_suggestions()`. **Depends on:** 3.3.1, 3.3.2, 3.3.3  
   - [ ] 6.3. Verify test passes. **Depends on:** 6.2

7. [ ] **Refactor & Verify**  
   - [ ] 7.1. Extract shared data-format helpers into `lib/data.sh`. **Depends on:** 3.3.1, 3.3.2, 3.3.3  
   - [ ] 7.2. Run extractor integration tests; confirm behavior. **Depends on:** 7.1

---

## 4. Selection Interface

1. [ ] **Write Failing Menu Display Test**  
   - [ ] 1.1. Create `tests/menu_interface.bats`. **Depends on:** 3.3.3  
   - [ ] 1.2. Stub `IDX=(1 2) CMD=(sh ssh) PKG=(dash openssh)` in test. **Depends on:** 1.1  
   - [ ] 1.3. Assert `display_menu` outputs expected lines. **Depends on:** 1.2

2. [ ] **Implement Menu Renderer**  
   - [ ] 2.1. Create `src/menu.sh` with `display_menu()` stub. **Depends on:** 1.3  
   - [ ] 2.2. Loop over arrays and `printf "%s) %s (%s)\n"`. **Depends on:** 2.1  
   - [ ] 2.3. Source `menu.sh` in test and confirm output. **Depends on:** 2.2

3. [ ] **Write Failing Input Handling Test**  
   - [ ] 3.1. Create `tests/input_handling.bats`. **Depends on:** 2.3  
   - [ ] 3.2. Simulate `printf "2\n" | dm --interactive`. **Depends on:** 3.1  
   - [ ] 3.3. Assert `$choice == 2`. **Depends on:** 3.2

4. [ ] **Implement Selection Logic**  
   - [ ] 4.1. In `dm.sh`, after `display_menu`, `read -rp "Choose: " choice`. **Depends on:** 3.3  
   - [ ] 4.2. Expose `choice` for tests (e.g. export or echo). **Depends on:** 4.1  
   - [ ] 4.3. Source `dm.sh` in test; confirm input handling. **Depends on:** 4.2

5. [ ] **Validate Numeric Choice**  
   - [ ] 5.1. Write test for non-numeric input (e.g. “x”) expecting exit code 1. **Depends on:** 4.1  
   - [ ] 5.2. Implement `is_number()` in `src/validate.sh`. **Depends on:** 5.1  
   - [ ] 5.3. Write unit tests for `is_number()` function alone. **Depends on:** 5.2  
   - [ ] 5.4. Integrate numeric check in `dm.sh` and rerun tests. **Depends on:** 5.3

6. [ ] **Range Checking**  
   - [ ] 6.1. Write test for out-of-range input (e.g. “10”) expecting exit code 1. **Depends on:** 5.4  
   - [ ] 6.2. Compute `max=${#IDX[@]}` and compare `choice`. **Depends on:** 6.1  
   - [ ] 6.3. Print error and exit on invalid. **Depends on:** 6.2  
   - [ ] 6.4. Verify range-check tests pass. **Depends on:** 6.3

7. [ ] **Refactor & Verify**  
   - [ ] 7.1. Move `is_number()` and range helpers into `src/validate.sh`. **Depends on:** 5.4, 6.3  
   - [ ] 7.2. Source in `dm.sh`. **Depends on:** 7.1  
   - [ ] 7.3. Run all menu + input + validation tests; confirm green. **Depends on:** 7.2

---

## 5. Command Reconstruction & Execution

1. [ ] **Write Failing Command-Build Tests**  
   - [ ] 1.1. Create `tests/build_command.bats`. **Depends on:** 4.3  
   - [ ] 1.2. Stub `CMD_PARTS=(typo arg1 arg2)` and `CMD=(typo ssh)`; assert `build_command 1 "${CMD_PARTS[@]}"` yields `ssh arg1 arg2`. **Depends on:** 1.1

2. [ ] **Split Original Command**  
   - [ ] 2.1. Write test for extracting first word and args array. **Depends on:** 1.2  
   - [ ] 2.2. Implement `split_command()` in `src/command.sh` using `read -ra`. **Depends on:** 2.1  
   - [ ] 2.3. Verify split test passes. **Depends on:** 2.2

3. [ ] **Replace Mistyped Binary**  
   - [ ] 3.1. Write test that sets `INDEX=1` and expects new command element. **Depends on:** 2.3  
   - [ ] 3.2. Overwrite `parts[0]` with `CMD[$INDEX]`. **Depends on:** 3.1  
   - [ ] 3.3. Preserve rest of `parts`. **Depends on:** 3.2  
   - [ ] 3.4. Verify replacement test passes. **Depends on:** 3.3

4. [ ] **Reassemble Command Array**  
   - [ ] 4.1. Write test for correct assembly of NEW_CMD array. **Depends on:** 3.4  
   - [ ] 4.2. Implement `reassemble_command()` combining `parts[@]`. **Depends on:** 4.1  
   - [ ] 4.3. Verify reassembly test. **Depends on:** 4.2

5. [ ] **Quoting & Edge Cases**  
   - [ ] 5.1. Write test for `CMD_PARTS=('typo' 'file name.txt' '--opt="val"')`. **Depends on:** 4.3  
   - [ ] 5.2. Ensure `split_command()` reads into an array without word-splitting. **Depends on:** 5.1  
   - [ ] 5.3. Ensure `reassemble_command()` uses the array directly in `exec`. **Depends on:** 5.2  
   - [ ] 5.4. Verify edge-case test passes. **Depends on:** 5.3

6. [ ] **Execute Command in Current Shell**  
   - [ ] 6.1. Write dry-run integration test asserting `NEW_CMD[@]` would be exec’d (mock exec). **Depends on:** 5.4  
   - [ ] 6.2. Parse `--dry-run` in `dm.sh`. **Depends on:** 6.1  
   - [ ] 6.3. If dry-run echo, else `exec "${NEW_CMD[@]}"`. **Depends on:** 6.2  
   - [ ] 6.4. Verify dry-run and real exec tests. **Depends on:** 6.3

7. [ ] **Refactor & Verify**  
   - [ ] 7.1. Move array utilities to `lib/array.sh`. **Depends on:** 5.2, 5.3  
   - [ ] 7.2. Source `command.sh` and `array.sh` in `dm.sh`. **Depends on:** 7.1  
   - [ ] 7.3. Run all build/execution tests; confirm green. **Depends on:** 7.2

---

## 6. Shell-Level Integration

1. [ ] **Write Failing E2E Docker Test Skeleton**  
   - [ ] 1.1. Create `tests/e2e_integration.bats`. **Depends on:** 5.4  
   - [ ] 1.2. Stub Docker build invocation; assert failure. **Depends on:** 1.1

2. [ ] **Prepare Termux-like Dockerfile**  
   - [ ] 2.1. Research and select minimal base image supporting Bash. **Depends on:** 1.4  
   - [ ] 2.2. Write `Dockerfile.termux`:  
     - [ ] 2.2.1. `FROM ubuntu:20.04` or Alpine. **Depends on:** 2.1  
     - [ ] 2.2.2. Install Bash, coreutils, and deps. **Depends on:** 2.2.1  
     - [ ] 2.2.3. Copy `src/` into `/usr/local/bin/` and `chmod +x`. **Depends on:** 2.2.2  
   - [ ] 2.3. Run `docker build -f Dockerfile.termux .`; expect success. **Depends on:** 2.2.3

3. [ ] **Implement End-to-End Test Logic**  
   - [ ] 3.1. In E2E test, build and run container mounting code. **Depends on:** 2.3  
   - [ ] 3.2. Inside shell, `source ~/.bashrc`. **Depends on:** 3.1  
   - [ ] 3.3. Run `foo123`, then `dm 1`. **Depends on:** 3.2  
   - [ ] 3.4. Assert corrected binary executed via sentinel file. **Depends on:** 3.3

4. [ ] **Write Failing Installer Tests**  
   - [ ] 4.1. Create `tests/install.bats` boilerplate. **Depends on:** 3.4  
   - [ ] 4.2. Stub `install.sh` invocation; expect failure. **Depends on:** 4.1

5. [ ] **Implement Installer Script**  
   - [ ] 5.1. Copy `src/*.sh` to `$PREFIX/bin/dm`. **Depends on:** 4.2  
   - [ ] 5.2. Append `source "$(which hook.sh)"` to `~/.bashrc` only if missing. **Depends on:** 5.1  
   - [ ] 5.3. Set script permissions `chmod +x`. **Depends on:** 5.1  
   - [ ] 5.4. Run manual sanity check and Bats. **Depends on:** 5.2, 5.3

6. [ ] **Ensure Idempotent Installation**  
   - [ ] 6.1. Write test: run `install.sh` twice; grep `.bashrc` for duplicates. **Depends on:** 5.4  
   - [ ] 6.2. Guard with `grep -qxF` before append. **Depends on:** 6.1  
   - [ ] 6.3. Verify idempotency test passes. **Depends on:** 6.2

7. [ ] **Post-Install E2E Verification**  
   - [ ] 7.1. In Docker E2E, replace manual `COPY` with `install.sh`. **Depends on:** 5.4  
   - [ ] 7.2. Run mistyped command; ensure `dm` menu appears and executes. **Depends on:** 7.1  
   - [ ] 7.3. Assert sentinel file updated. **Depends on:** 7.2

8. [ ] **Refactor & Verify**  
   - [ ] 8.1. Collect common Docker/test helper functions into `tests/helpers.sh`. **Depends on:** 3.4  
   - [ ] 8.2. Re-run full test suite; confirm all tests pass. **Depends on:** all above