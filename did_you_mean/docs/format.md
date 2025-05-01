## Data Format for `extract_suggestions`

The `extract_suggestions` utility outputs three arrays of suggestions:

- `IDX`: suggestion indices
- `CMD`: suggested commands
- `PKG`: corresponding package names

The output format is chosen based on the availability of `jq`:

- If `jq` is installed (detected via `command -v jq`), a JSON output path is planned (to be implemented).
- Otherwise, a minimal Bash-array format is used, emitting:
  ```bash
  export IDX=(...)
  export CMD=(...)
  export PKG=(...)
  ```

This default ensures minimal external dependencies while providing
structured output easily consumed by Bash scripts.