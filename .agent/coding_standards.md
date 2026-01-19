# Coding Standards

## Shell Scripts

Every script starts with:
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

## Testing

- Framework: **BATS**
- Location: `utilities/<name>/tests/*.bats`
- Run: `bats utilities/<name>/tests/`

## Commits

- Prefix with utility name: `summarise_project: fix edge case`
- General changes: `install: add dependency management`

## Dependencies

If utility has required deps, create `deps.sh`:
```bash
declare -A DEPS=(
  [fd]="sudo apt install fd-find"
  [tree]="sudo apt install tree"
)
```
