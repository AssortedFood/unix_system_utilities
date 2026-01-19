# Lightweight Installer Improvements

## Bootstrap

Fresh Debian 12 minimal has only `tar` - no wget/curl/git. Bootstrap one-liner:

**As root:**
```
apt update && apt install -y wget && wget -qO- https://github.com/AssortedFood/unix_system_utilities/archive/main.tar.gz | tar xz && cd unix_system_utilities-main && ./install.sh
```

**As normal user:**
```
sudo apt update && sudo apt install -y wget && wget -qO- https://github.com/AssortedFood/unix_system_utilities/archive/main.tar.gz | tar xz && cd unix_system_utilities-main && ./install.sh
```

The installer itself must also handle both cases - use `sudo` only when `$EUID -ne 0`.

---

## Philosophy

The installer should work on a **fresh Debian 12 minimal install** with zero additional dependencies. Pure bash, maximum UX, minimum friction.

**Constraints:**
- No external dependencies (no gum, fzf, dialog, etc.)
- Use only bash built-ins + coreutils (awk, sed, grep, tput)
- Sensible defaults - don't ask if we can infer
- Install all by default - most users want everything
- Always install deps - don't ask

---

## Proposed UX Flow

### Default (no args): Install All

Example output:
```
Unix System Utilities
────────────────────────────────────

Installing:
  copy        - Copy to clipboard via OSC52
  sshl        - SSH with automatic port forwarding
  sp          - Summarize project files to markdown
  awt         - Create git worktrees with setup
  rwt         - Remove git worktrees safely
  prompt      - Custom bash prompt (sourced)
  tmux-setup  - Install tmux and config

Skipped (platform-specific):
  wsl-bridge  - WSL only
  dm          - Termux only

Installing dependencies...
  ✓ jq
  ✓ ripgrep
  ✓ tmux
  ✓ fd-find
  ✓ tree

Writing to ~/.bashrc...
  ✓ Done

Run: source ~/.bashrc
```

### Custom Selection: `--select`

Interactive numbered selection menu (existing behavior, moved behind flag).

### List Mode: `--list`

Table showing all utilities with description and platform.

### Uninstall: `--uninstall`

Removes managed block from bashrc. No confirmation prompt.

---

## Implementation Changes

### 1. Restructure main flow

- Default action becomes `do_install_all`
- Move interactive selection to `--select` flag

### 2. Simplify dependency installation

- Remove the y/n/m menu - always install
- Single `sudo -v` prompt at start if not root
- Install all missing deps with `-y` flag
- Show ✓/✗ status for each

### 3. Integrate tmux setup

Move tmux post-install hook into the core tmux_config install process - when tmux-setup is selected, it installs tmux and copies config as part of installation, not as a separate post-install step.

### 4. Remove clipboard copy at end

The "copied 'source ~/.bashrc' to clipboard" is unnecessary. Just tell users what to run.

### 5. Update README

Replace current install instructions with bootstrap one-liners (root and normal user). Document `--select`, `--list`, `--uninstall` flags.

### 6. Update project_context.md

Reflect new installer flow and CLI options.

---

## CLI Summary

| Command | Behavior |
|---------|----------|
| `./install.sh` | Install all compatible utilities + deps |
| `./install.sh --select` | Interactive numbered selection |
| `./install.sh --list` | Show available utilities table |
| `./install.sh --uninstall` | Remove from bashrc |
| `./install.sh --help` | Show help |
