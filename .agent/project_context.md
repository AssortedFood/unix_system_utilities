# Project Context

> **Last Updated:** 2026-01-19
>
> **Reminder:** Update this file after completing significant milestones.

## Current Status

### Stable Utilities
| Utility | Alias | Status |
|---------|-------|--------|
| copy_via_osc52 | `copy` | Complete - clipboard via OSC52/xclip/pbcopy |
| ssh_port_forward | `sshl` | Complete - SSH with saved port profiles |
| summarise_project | `sp` | Complete - aggregates project files to markdown |
| worktree_add | `awt` | Complete - create git worktrees with auto package manager detection |
| worktree_remove | `rwt` | Complete - remove git worktrees with safety checks + dynamic completions |
| prompt | (sourced) | Complete - custom bash prompt with git integration |
| wsl_bridge | `wsl-bridge` | Complete - WSL2 port forwarding (WSL only) |
| tmux_config | `tmux-setup` | Complete - install tmux and symlink config |

### In Development
| Utility | Status | Notes |
|---------|--------|-------|
| did_you_mean | Partial | Termux only. Sections 1-3 complete (hook, parser, extractor). Sections 4-6 pending. See `did_you_mean/PLAN.md` |

## Repository Structure

```
unix_system_utilities/
├── .agent/                       # AI instructions and plans
├── install.sh                    # Interactive installer (sources lib/common.sh)
├── lib/
│   └── common.sh                 # Shared functions (colors, logging, platform detection)
└── utilities/
    ├── copy_via_osc52/
    ├── ssh_port_forward/
    │   └── deps.sh               # jq
    ├── summarise_project/
    │   └── deps.sh               # fd, tree
    ├── did_you_mean/             # Termux only
    ├── worktree_add/
    │   └── tests/
    ├── worktree_remove/
    │   ├── completions.sh        # Dynamic autocomplete
    │   └── tests/
    ├── prompt/                   # Sourced, not aliased
    ├── wsl_bridge/               # WSL only
    │   ├── deps.sh               # jq
    │   └── update-portproxy.ps1
    └── tmux_config/
        └── .tmux.conf
```

## Active Plan

None - all planned work complete.

## Recently Completed

**Plan file:** `.agent/plans/02-lightweight-installer.md` - **COMPLETED**

Improved install.sh UX while keeping it dependency-free:
- Default now installs all compatible utilities (no interactive prompts)
- Added `--select` for interactive mode
- Added `--list` to show utilities table
- Auto-installs deps with `-y` (single sudo prompt, ✓/✗ status)
- Removed clipboard copy at end

## Completed Work

**Plan file:** `.agent/plans/01-restructuring.md` - **COMPLETED**

### Completed Tasks
- [x] Created `utilities/` directory structure
- [x] Created `lib/common.sh` with shared functions
- [x] Migrated `worktree_add` from ~/scripts/add-work-tree.sh
- [x] Migrated `worktree_remove` from ~/scripts/remove-work-tree.sh with dynamic completions
- [x] Migrated `prompt` from ~/scripts/prompt.sh (sourced script)
- [x] Migrated `wsl_bridge` from ~/scripts/wsl-bridge.sh with scheduled task approach
- [x] Created `tmux_config` with .tmux.conf
- [x] Created `deps.sh` for ssh_port_forward, summarise_project, wsl_bridge
- [x] Rewrote `install.sh` with interactive selection, dependency management, managed block
- [x] install.sh sources lib/common.sh (no duplicated code)
- [x] Added BATS tests for worktree_add and worktree_remove

## Architecture Notes

```
install.sh sources lib/common.sh
         ↓
Default: install-all → aggregate deps.sh → auto-install missing → write to ~/.bashrc managed block
         ↓
--select: interactive selection → same flow as above
```

Script types:
- `alias` → adds `alias name="/path/to/main.sh"` to managed block
- `source` → adds `source "/path/to/main.sh"` to managed block
- Completions → sources completions.sh for associated aliases

Platform-specific (only shown in installer on matching platform):
- `wsl_bridge` → WSL only (detected via `/proc/version`)
- `did_you_mean` → Termux only (detected via `$TERMUX_VERSION`)

## Install Configuration

**CLI options:**
| Command | Behavior |
|---------|----------|
| `./install.sh` | Install all compatible utilities + deps |
| `./install.sh --select` | Interactive numbered selection |
| `./install.sh --list` | Show available utilities table |
| `./install.sh --uninstall` | Remove from ~/.bashrc |
| `./install.sh --help` | Show help |

The installer uses a managed block in ~/.bashrc:
```bash
# >>> unix_system_utilities >>>
alias copy="/path/to/utilities/copy_via_osc52/main.sh"
source "/path/to/utilities/prompt/main.sh"
# <<< unix_system_utilities <<<
```
