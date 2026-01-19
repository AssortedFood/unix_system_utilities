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
│   ├── common.sh                 # Shared functions (colors, logging)
│   └── deps.sh                   # Aggregates deps from utilities, dedupes, installs
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
    └── wsl_bridge/               # NEW - WSL only, from ~/scripts/wsl-bridge.sh
        ├── main.sh
        └── update-portproxy.ps1  # PowerShell script for scheduled task
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
   - Reads config.json
   - Clears existing port forwarding rules
   - Adds new rules for each port

4. **Fallback**: If scheduled task doesn't exist, prompts user to run `--setup` first

## Enhanced install.sh

### Interactive Selection

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

Install.sh sources `deps.sh` from each selected utility, aggregates missing deps, and offers:
- `y` = Install all
- `n` = Skip (warn which utilities may not work)
- `m` = Show manual installation commands

### Support for Different Script Types

| Type | Installation Method |
|------|---------------------|
| `alias` | Add `alias name="/path/to/main.sh"` to ~/.bash_aliases |
| `source` | Add `source "/path/to/main.sh"` to ~/.bashrc |
| Completions | Source the completions.sh file in ~/.bashrc |

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
5. Create `lib/deps.sh` - aggregates deps from selected utilities, dedupes, offers install

### Phase 3: Script Migrations
6. Migrate `utilities/worktree_add/`
7. Migrate `utilities/worktree_remove/` with dynamic completions
8. Migrate `utilities/prompt/` as sourced script
9. Migrate `utilities/wsl_bridge/` with scheduled task setup

### Phase 4: Enhanced Installer
10. Rewrite `install.sh` with:
    - Interactive selection UI
    - Dependency installation with sudo handling
    - Support for ALIASES, SOURCES, COMPLETIONS arrays
    - Uninstall functionality

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
- `lib/deps.sh` (aggregates and dedupes deps across utilities)
- `utilities/ssh_port_forward/deps.sh`
- `utilities/summarise_project/deps.sh`
- `utilities/worktree_add/main.sh` (migrated + updated)
- `utilities/worktree_remove/main.sh` (migrated)
- `utilities/worktree_remove/completions.sh` (new dynamic version)
- `utilities/prompt/main.sh` (migrated)
- `utilities/wsl_bridge/main.sh` (migrated + scheduled task logic)
- `utilities/wsl_bridge/update-portproxy.ps1` (new PowerShell script)

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
