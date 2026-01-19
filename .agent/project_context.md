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

### In Development
| Utility | Status | Notes |
|---------|--------|-------|
| did_you_mean | Partial | Termux only. Sections 1-3 complete (hook, parser, extractor). Sections 4-6 pending. See `did_you_mean/PLAN.md` |

## Active Work: Repository Restructuring

**Plan file:** `.agent/plans/01-restructuring.md`

### Pending Directory Restructure
- [ ] Create `utilities/` directory
- [ ] Move existing utilities into `utilities/`
- [ ] Create `lib/` directory

### Pending Migrations (from ~/scripts/)
- `add-work-tree.sh` → `utilities/worktree_add/` (alias: awt)
- `remove-work-tree.sh` → `utilities/worktree_remove/` (alias: rwt)
- `prompt.sh` → `utilities/prompt/` (sourced, not aliased)
- `wsl-bridge.sh` → `utilities/wsl_bridge/` (alias: wsl-bridge, WSL only)

### Pending Infrastructure
- [ ] `lib/common.sh` - shared functions
- [ ] `lib/deps.sh` - aggregates deps from utilities
- [ ] `deps.sh` for utilities with dependencies (ssh_port_forward, summarise_project)
- [ ] Enhanced `install.sh` with interactive selection

## Recent Decisions

- **Directory structure**: All utilities live in `utilities/` subdirectory (cleaner root)
- **No manifests**: Simple arrays in install.sh (ALIASES, SOURCES, COMPLETIONS)
- **Per-utility deps.sh**: Each utility with deps has optional `deps.sh` with install commands
- **Package manager detection**: awt uses lockfile to determine npm/pnpm/yarn/bun
- **rwt autocomplete**: Dynamic worktree detection (no hardcoded paths)
- **wsl-bridge UAC**: Scheduled task approach for UAC-free operation after initial setup
- **Platform filtering**: WSL/Termux utilities not shown in installer on other platforms

## Architecture Notes

```
install.sh has ALIASES, SOURCES, COMPLETIONS arrays
         ↓
Interactive selection → aggregate deps.sh files → dedupe → offer install → install aliases/sources/completions
```

Script types:
- `alias` → adds to ~/.bash_aliases
- `source` → adds source line to ~/.bashrc
- Completions → sources completions.sh in ~/.bashrc

Platform-specific:
- `wsl_bridge` → WSL only (detected via `/proc/version`)
- `did_you_mean` → Termux only (detected via `$TERMUX_VERSION`)
