# Unix System Utilities Restructuring Plan

## Overview

Migrate scripts from `~/scripts/` into this repo with proper structure, enhance `install.sh` with interactive selection and dependency management, and fix the rwt autocomplete.

## New Directory Structure

```
unix_system_utilities/
├── .agent/                       # AI instructions and plans
├── install.sh                    # Enhanced interactive installer
├── README.md
├── lib/
│   └── common.sh                 # Shared functions (colors, logging)
└── utilities/
    ├── copy_via_osc52/
    │   └── main.sh
    ├── ssh_port_forward/
    │   ├── main.sh
    │   ├── deps.sh               # jq
    │   └── .profiles
    ├── summarise_project/
    │   ├── main.sh
    │   ├── deps.sh               # fd, tree
    │   ├── .summaryignore
    │   └── tests/
    ├── did_you_mean/               # Termux only
    │   └── (existing structure)
    ├── worktree_add/             # NEW - from ~/scripts/add-work-tree.sh
    │   ├── main.sh
    │   └── tests/
    ├── worktree_remove/          # NEW - from ~/scripts/remove-work-tree.sh
    │   ├── main.sh
    │   ├── completions.sh        # Dynamic autocomplete
    │   └── tests/
    ├── prompt/                   # NEW - from ~/scripts/prompt.sh
    │   └── main.sh
    ├── wsl_bridge/               # NEW - WSL only, from ~/scripts/wsl-bridge.sh
    │   ├── main.sh
    │   └── update-portproxy.ps1  # PowerShell script for scheduled task
    └── tmux_config/              # NEW
        ├── main.sh               # Installs tmux + symlinks config
        └── .tmux.conf            # tmux configuration
```

## Install Configuration

Arrays in `install.sh`:

```bash
ALIASES=(
  "copy:utilities/copy_via_osc52/main.sh"
  "sshl:utilities/ssh_port_forward/main.sh"
  "sp:utilities/summarise_project/main.sh"
  "awt:utilities/worktree_add/main.sh"
  "rwt:utilities/worktree_remove/main.sh"
  "wsl-bridge:utilities/wsl_bridge/main.sh"      # WSL only
  "dm:utilities/did_you_mean/dm.sh"              # Termux only
  "tmux-setup:utilities/tmux_config/main.sh"
)

SOURCES=(
  "utilities/prompt/main.sh"
)

COMPLETIONS=(
  "utilities/worktree_remove/completions.sh"
)
```

**Dependencies:** Each utility with deps has optional `deps.sh`:
```bash
# utilities/summarise_project/deps.sh
declare -A DEPS=(
  [fd]="sudo apt install fd-find"
  [tree]="sudo apt install tree"
)
```
Install.sh sources these for selected utilities and offers to install missing deps.

**Platform:** Installer detects WSL (`grep -q Microsoft /proc/version`) for UI display.

## Script Migrations

### 1. worktree_add (awt)

- Migrate from `~/scripts/add-work-tree.sh`
- Detect package manager from lockfile:
  - `pnpm-lock.yaml` → `pnpm i --approve-builds`
  - `package-lock.json` → `npm i`
  - `yarn.lock` → `yarn`
  - `bun.lockb` → `bun i`
- Ensure `node_modules` is explicitly excluded from gitignored file copy

### 2. worktree_remove (rwt)

- Migrate from `~/scripts/remove-work-tree.sh`
- Create `completions.sh` with **dynamic** worktree detection (no hardcoded paths)

**Dynamic completion logic:**
```bash
_rwt_completions() {
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || return

  local branches
  branches=$(git -C "$repo_root" worktree list --porcelain 2>/dev/null \
    | grep "^branch" \
    | sed 's|branch refs/heads/||')

  COMPREPLY=( $(compgen -W "$branches" -- "${COMP_WORDS[1]}") )
}
complete -F _rwt_completions rwt
```

### 3. prompt

- Move to `prompt/main.sh`
- Type: `source` (not aliased)
- Will add `source "/path/to/prompt/main.sh"` to ~/.bashrc

**Content:**
```bash
# Config
PROMPT_PATH_SEGMENTS=3  # Number of visible path segments to keep
export VIRTUAL_ENV_DISABLE_PROMPT=1  # We handle venv display ourselves

format_time() {
  local t=$1
  if (( t < 60 )); then
    echo "${t}s"
  elif (( t < 3600 )); then
    echo "$((t / 60))m $((t % 60))s"
  else
    echo "$((t / 3600))h $(((t % 3600) / 60))m"
  fi
}

git_status_color() {
  local status=$(git status --porcelain 2>/dev/null)

  if [[ -n "$status" ]]; then
    if echo "$status" | grep -q '^.\?[MD]'; then
      echo "33"  # yellow — modified
    else
      echo "32"  # green — untracked only
    fi
    return
  fi

  # Clean working tree — check if ahead of remote
  local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)

  if [[ -n "$ahead" && "$ahead" -gt 0 ]]; then
    echo "37"        # white — ahead, need to push
  else
    echo "38;5;245"  # grey — in sync
  fi
}

truncate_path() {
  local path="$1"
  local max_segments="$PROMPT_PATH_SEGMENTS"

  local prefix=""
  local working_path="$path"

  if [[ "$path" == "~"* ]]; then
    prefix="~"
    working_path="${path#\~}"
  fi

  working_path="${working_path#/}"
  local parts=()
  IFS='/' read -ra parts <<< "$working_path"

  local count=${#parts[@]}

  if (( count <= max_segments )); then
    echo "$path"
    return
  fi

  local result="${prefix}/…"
  for (( i = count - max_segments; i < count; i++ )); do
    result="${result}/${parts[i]}"
  done

  echo "$result"
}

path_prompt() {
  local full_path="$PWD"
  [[ "$full_path" == "$HOME"* ]] && full_path="~${full_path#$HOME}"

  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "$branch" || -z "$git_root" ]]; then
    echo -e "$(truncate_path "$full_path")"
    return
  fi

  local git_root_name="${git_root##*/}"
  local git_root_display="$git_root"
  [[ "$git_root_display" == "$HOME"* ]] && git_root_display="~${git_root_display#$HOME}"

  local truncated=$(truncate_path "$full_path")

  # Transform branch: feature/some-feature -> feature-some-feature
  local branch_as_dir="${branch//\//-}"

  if [[ "$git_root_name" == "$branch_as_dir" && "$truncated" == *"/$git_root_name"* ]]; then
    local color=$(git_status_color)
    local before="${truncated%/$git_root_name*}"
    local after="${truncated#*$git_root_name}"
    echo -e "${before}/\e[${color}m${git_root_name}\e[38;5;245m${after}"
  else
    local color=$(git_status_color)
    echo -e "${truncated} \e[${color}m${branch}"
  fi
}

prompt_char_color() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "37"  # white when in venv
  else
    echo "38;5;245"  # grey normally
  fi
}

PS1='$([ $? -ne 0 ] && echo "\[\e[31m\]! ")\[\e[38;5;245m\]$(path_prompt)\[\e[90m\]$([ \j -gt 0 ] && echo " [\j]")\[\e[0m\]\n\[\e[$(prompt_char_color)m\]❯\[\e[0m\] '
```

### 4. wsl_bridge

- Move to `wsl_bridge/main.sh`
- Platform: WSL only (not shown in installer on non-WSL)
- Alias: `wsl-bridge`

**Directory structure:**
```
wsl_bridge/
├── main.sh                    # Entry point (bash)
└── update-portproxy.ps1       # PowerShell script run by scheduled task
```

**Genericization:**
- Make ports configurable: `wsl-bridge 2222` or `wsl-bridge 22 2222 8080`
- Support multiple ports in single invocation
- IP detection already dynamic (`hostname -I`)

**UAC-free Scheduled Task Approach:**

1. **Setup** (`wsl-bridge --setup`):
   - Copies `update-portproxy.ps1` to `%USERPROFILE%\.wsl-bridge\`
   - Creates Windows Scheduled Task "WSL-PortForward" with:
     - "Run with highest privileges" enabled
     - Action: runs the PowerShell script
   - Requires UAC **once** during setup

2. **Usage** (`wsl-bridge 2222 8080`):
   - Writes WSL IP and ports to `%USERPROFILE%\.wsl-bridge\config.json`
   - Triggers scheduled task via `schtasks /Run /TN "WSL-PortForward"`
   - No UAC prompt (task is pre-authorized)

3. **PowerShell script** (`update-portproxy.ps1`):
   ```powershell
   $configPath = "$env:USERPROFILE\.wsl-bridge\config.json"
   $config = Get-Content $configPath | ConvertFrom-Json

   # Clear existing rules for managed ports
   foreach ($port in $config.ports) {
       netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 2>$null
   }

   # Add new rules
   foreach ($port in $config.ports) {
       netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$($config.ip)
   }
   ```

4. **Setup creates task** (`--setup`):
   ```bash
   # From WSL, create the scheduled task:
   powershell.exe -Command "schtasks /Create /TN 'WSL-PortForward' /TR 'powershell.exe -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.wsl-bridge\\update-portproxy.ps1\"' /SC ONCE /ST 00:00 /RL HIGHEST /F"
   ```

5. **Fallback**: If scheduled task doesn't exist, prompts user to run `--setup` first

### 5. tmux_config

- Alias: `tmux-setup`
- Installs tmux and symlinks config

**Source:** Copy from `/home/hb/.tmux.conf`

**main.sh behavior:**
1. Install tmux if not present (`sudo apt install tmux`)
2. Backup existing `~/.tmux.conf` if present
3. Symlink `utilities/tmux_config/.tmux.conf` to `~/.tmux.conf`

## Enhanced install.sh

### Interactive Selection

**Note:** Interactive UI should be implemented last. Work iteratively with human user for feedback on UX. Start with simple numbered list if time-constrained; fancy arrow-key selection can come later.

Example (on WSL):
```
Select utilities to install (space to toggle, enter to confirm):

  [x] copy        - Copy files to clipboard via OSC52
  [x] sshl        - SSH with automatic port forwarding
  [x] sp          - Summarize project files to markdown
  [x] awt         - Create git worktrees with setup
  [x] rwt         - Remove git worktrees safely
  [ ] prompt      - Custom bash prompt with git integration
  [x] wsl-bridge  - WSL2 port forwarding
```
Platform-specific utilities only shown when applicable:
- `wsl-bridge` - WSL only (detected via `/proc/version`)
- `dm` (did_you_mean) - Termux only (detected via `$TERMUX_VERSION`)

### Dependency Management

Aggregation logic lives in `install.sh` (no separate lib/deps.sh):

```bash
# Aggregate deps from selected utilities
declare -A ALL_DEPS=()

for util in "${SELECTED_UTILS[@]}"; do
  deps_file="utilities/$util/deps.sh"
  if [[ -f "$deps_file" ]]; then
    source "$deps_file"  # sources DEPS associative array
    for cmd in "${!DEPS[@]}"; do
      ALL_DEPS[$cmd]="${DEPS[$cmd]}"  # dedupes by key
    done
    unset DEPS
  fi
done

# Check which are missing
MISSING=()
for cmd in "${!ALL_DEPS[@]}"; do
  command -v "$cmd" &>/dev/null || MISSING+=("$cmd")
done
```

User is offered:
- `y` = Install all missing with sudo
- `n` = Skip (warn which utilities may not work)
- `m` = Show manual installation commands

### Support for Different Script Types

| Type | Installation Method |
|------|---------------------|
| `alias` | Add `alias name="/path/to/main.sh"` to ~/.bashrc |
| `source` | Add `source "/path/to/main.sh"` to ~/.bashrc |
| Completions | Source the completions.sh file in ~/.bashrc |

**Managed Block Approach:**

All entries go in a single managed block in `~/.bashrc`:

```bash
# >>> unix_system_utilities >>>
alias copy="/path/to/utilities/copy_via_osc52/main.sh"
alias sshl="/path/to/utilities/ssh_port_forward/main.sh"
source "/path/to/utilities/prompt/main.sh"
source "/path/to/utilities/worktree_remove/completions.sh"
# <<< unix_system_utilities <<<
```

This makes uninstall clean - remove the whole block and rewrite with remaining items.

### Uninstall Support

`./install.sh --uninstall awt rwt` removes aliases/sources/completions

Does NOT uninstall dependencies (they may be used by other tools).

## Implementation Order

### Phase 1: Directory Restructure
1. Create `utilities/` directory
2. Move existing utilities into `utilities/`
3. Create `lib/` directory

### Phase 2: Infrastructure
4. Create `lib/common.sh` - colors, logging functions

### Phase 3: Script Migrations
5. Migrate `utilities/worktree_add/`
6. Migrate `utilities/worktree_remove/` with dynamic completions
7. Migrate `utilities/prompt/` as sourced script
8. Migrate `utilities/wsl_bridge/` with scheduled task setup
9. Migrate `utilities/tmux_config/`

### Phase 4: Enhanced Installer
10. Rewrite `install.sh` with:
    - Dependency aggregation and installation (with sudo handling)
    - Support for ALIASES, SOURCES, COMPLETIONS arrays
    - Managed block in ~/.bashrc
    - Uninstall functionality
    - Interactive selection UI (implement last, iterate with human feedback)

### Phase 5: Testing
11. Add BATS tests for new utilities
12. Add completion tests for rwt
13. Update README.md

## Files to Modify/Create

**Move to utilities/:**
- `copy_via_osc52/` → `utilities/copy_via_osc52/`
- `ssh_port_forward/` → `utilities/ssh_port_forward/`
- `summarise_project/` → `utilities/summarise_project/`
- `did_you_mean/` → `utilities/did_you_mean/`

**Modify:**
- `install.sh` - Complete rewrite

**Create:**
- `lib/common.sh`
- `utilities/ssh_port_forward/deps.sh`
- `utilities/summarise_project/deps.sh`
- `utilities/worktree_add/main.sh` (migrated + updated)
- `utilities/worktree_remove/main.sh` (migrated)
- `utilities/worktree_remove/completions.sh` (new dynamic version)
- `utilities/prompt/main.sh` (migrated)
- `utilities/wsl_bridge/main.sh` (migrated + scheduled task logic)
- `utilities/wsl_bridge/update-portproxy.ps1` (new PowerShell script)
- `utilities/tmux_config/main.sh` (installs tmux + symlinks config)
- `utilities/tmux_config/.tmux.conf` (tmux configuration)

## Verification

**Install flow:**
1. Run `./install.sh` - verify interactive selection UI works
2. Select a subset of utilities - verify only those are installed
3. Test dependency detection with missing `jq`
4. Run `./install.sh --uninstall awt` - verify removal works

**Utility tests:**
5. `awt` - create worktree in repo with pnpm-lock.yaml, verify runs `pnpm i --approve-builds`
6. `awt` - verify node_modules is NOT copied from source worktree
7. `rwt` - test autocomplete in different repositories (not hardcoded)
8. `rwt` - verify removal with safety checks
9. `prompt` - verify it's sourced (not aliased) and prompt displays correctly
10. `wsl-bridge --setup` - verify scheduled task creation (on WSL)
11. `wsl-bridge 2222` - verify port forwarding without UAC prompt (after setup)
12. `wsl-bridge` - verify not shown in installer on non-WSL systems
13. `dm` - verify not shown in installer on non-Termux systems

**Existing tests:**
14. Run `bats utilities/summarise_project/tests/` - existing tests should pass
15. Run `bats utilities/did_you_mean/tests/` - existing tests should pass
