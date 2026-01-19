#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────────────────────────────────
# Unix System Utilities - Installer
# ──────────────────────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RC="$HOME/.bashrc"
MANAGED_START="# >>> unix_system_utilities >>>"
MANAGED_END="# <<< unix_system_utilities <<<"

# Source common functions (colors, logging, platform detection)
source "$REPO_ROOT/lib/common.sh"

# Additional colors for install.sh
if [ -t 1 ]; then
  BOLD=$(tput bold)
else
  BOLD=''
fi

# ──────────────────────────────────────────────────────────────────────────────
# Configuration
# Format: "alias:path:description:platform"
# Platform: all, wsl, termux (empty = all)
# ──────────────────────────────────────────────────────────────────────────────

ALIASES=(
  "copy:utilities/copy_via_osc52/main.sh:Copy to clipboard via OSC52:"
  "sshl:utilities/ssh_port_forward/main.sh:SSH with automatic port forwarding:"
  "sp:utilities/summarise_project/main.sh:Summarize project files to markdown:"
  "awt:utilities/worktree_add/main.sh:Create git worktrees with setup:"
  "rwt:utilities/worktree_remove/main.sh:Remove git worktrees safely:"
  "wsl-bridge:utilities/wsl_bridge/main.sh:WSL2 port forwarding:wsl"
  "dm:utilities/did_you_mean/dm.sh:Command suggestions:termux"
  "tmux-setup:utilities/tmux_config/main.sh:Install tmux and config:"
)

SOURCES=(
  "utilities/prompt/main.sh:Custom bash prompt with git integration:"
)

COMPLETIONS=(
  "rwt:utilities/worktree_remove/completions.sh"
)

# ──────────────────────────────────────────────────────────────────────────────
# Platform Matching
# ──────────────────────────────────────────────────────────────────────────────

matches_platform() {
  local platform="$1"
  case "$platform" in
    "") return 0 ;;
    wsl) is_wsl ;;
    termux) is_termux ;;
    *) return 1 ;;
  esac
}

platform_label() {
  local platform="$1"
  case "$platform" in
    wsl) echo "WSL only" ;;
    termux) echo "Termux only" ;;
    *) echo "" ;;
  esac
}

# ──────────────────────────────────────────────────────────────────────────────
# Utility Functions
# ──────────────────────────────────────────────────────────────────────────────

# Get utility directory from path
get_util_dir() {
  local path="$1"
  dirname "$path" | sed 's|^utilities/||'
}

# ──────────────────────────────────────────────────────────────────────────────
# Dependency Management
# ──────────────────────────────────────────────────────────────────────────────

declare -A ALL_DEPS=()

aggregate_deps() {
  local selected_utils=("$@")

  for util_dir in "${selected_utils[@]}"; do
    local deps_file="$REPO_ROOT/utilities/$util_dir/deps.sh"
    if [[ -f "$deps_file" ]]; then
      # Source in subshell to avoid polluting our namespace
      local deps_output
      deps_output=$(
        declare -A DEPS=()
        source "$deps_file"
        for cmd in "${!DEPS[@]}"; do
          echo "$cmd:${DEPS[$cmd]}"
        done
      )
      while IFS=: read -r cmd install_cmd; do
        [[ -n "$cmd" ]] && ALL_DEPS[$cmd]="$install_cmd"
      done <<< "$deps_output"
    fi
  done
}

check_missing_deps() {
  local -a missing=()
  for cmd in "${!ALL_DEPS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  echo "${missing[*]}"
}

install_deps() {
  local missing="$1"
  [[ -z "$missing" ]] && return 0

  echo ""
  echo "Installing dependencies..."

  # Use sudo only if not running as root
  local sudo_prefix=""
  if [[ $EUID -ne 0 ]]; then
    sudo_prefix="sudo "
    # Validate sudo once upfront
    sudo -v || { log_error "sudo required for dependency installation"; return 1; }
  fi

  for cmd in $missing; do
    local install_cmd="${ALL_DEPS[$cmd]}"
    if eval "${sudo_prefix}${install_cmd}" &>/dev/null; then
      echo "  ${GREEN}✓${RESET} $cmd"
    else
      echo "  ${RED}✗${RESET} $cmd (failed)"
    fi
  done
}

# ──────────────────────────────────────────────────────────────────────────────
# Build Available Lists
# ──────────────────────────────────────────────────────────────────────────────

declare -a AVAILABLE_ALIASES=()
declare -a AVAILABLE_SOURCES=()
declare -a SKIPPED_ALIASES=()
declare -a SELECTED_ITEMS=()

build_available_list() {
  AVAILABLE_ALIASES=()
  AVAILABLE_SOURCES=()
  SKIPPED_ALIASES=()

  for entry in "${ALIASES[@]}"; do
    IFS=: read -r name path desc platform <<< "$entry"
    if matches_platform "$platform"; then
      AVAILABLE_ALIASES+=("$name:$path:$desc")
    else
      local plabel
      plabel=$(platform_label "$platform")
      SKIPPED_ALIASES+=("$name:$desc:$plabel")
    fi
  done

  for entry in "${SOURCES[@]}"; do
    IFS=: read -r path desc platform <<< "$entry"
    if matches_platform "$platform"; then
      AVAILABLE_SOURCES+=("$path:$desc")
    fi
  done
}

# ──────────────────────────────────────────────────────────────────────────────
# Interactive Selection (--select)
# ──────────────────────────────────────────────────────────────────────────────

show_selection_menu() {
  echo ""
  echo "${BOLD}Select utilities to install:${RESET}"
  echo "(Enter numbers separated by spaces, 'a' for all, or 'q' to quit)"
  echo ""

  local idx=1
  local -a items=()

  # Aliases
  for entry in "${AVAILABLE_ALIASES[@]}"; do
    IFS=: read -r name path desc <<< "$entry"
    printf "  %2d. %-12s - %s\n" "$idx" "$name" "$desc"
    items+=("alias:$name:$path")
    ((idx++))
  done

  # Sources
  for entry in "${AVAILABLE_SOURCES[@]}"; do
    IFS=: read -r path desc <<< "$entry"
    local name
    name=$(basename "$(dirname "$path")")
    printf "  %2d. %-12s - %s (sourced)\n" "$idx" "$name" "$desc"
    items+=("source:$name:$path")
    ((idx++))
  done

  echo ""
  read -p "Selection: " -r selection

  if [[ "$selection" == "q" ]]; then
    echo "Cancelled."
    exit 0
  fi

  SELECTED_ITEMS=()
  if [[ "$selection" == "a" ]]; then
    SELECTED_ITEMS=("${items[@]}")
  else
    for num in $selection; do
      if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num < idx )); then
        SELECTED_ITEMS+=("${items[$((num-1))]}")
      fi
    done
  fi

  if [[ ${#SELECTED_ITEMS[@]} -eq 0 ]]; then
    log_warn "No utilities selected"
    exit 0
  fi
}

select_all() {
  SELECTED_ITEMS=()

  for entry in "${AVAILABLE_ALIASES[@]}"; do
    IFS=: read -r name path desc <<< "$entry"
    SELECTED_ITEMS+=("alias:$name:$path")
  done

  for entry in "${AVAILABLE_SOURCES[@]}"; do
    IFS=: read -r path desc <<< "$entry"
    local name
    name=$(basename "$(dirname "$path")")
    SELECTED_ITEMS+=("source:$name:$path")
  done
}

# ──────────────────────────────────────────────────────────────────────────────
# Installation
# ──────────────────────────────────────────────────────────────────────────────

get_managed_block() {
  local -a lines=()

  for item in "${SELECTED_ITEMS[@]}"; do
    IFS=: read -r type name path <<< "$item"
    local full_path="$REPO_ROOT/$path"

    chmod +x "$full_path" 2>/dev/null || true

    case "$type" in
      alias)
        lines+=("alias $name=\"$full_path\"")
        ;;
      source)
        lines+=("source \"$full_path\"")
        ;;
    esac
  done

  # Add completions for selected aliases
  for comp_entry in "${COMPLETIONS[@]}"; do
    IFS=: read -r alias_name comp_path <<< "$comp_entry"
    for item in "${SELECTED_ITEMS[@]}"; do
      IFS=: read -r type name path <<< "$item"
      if [[ "$type" == "alias" && "$name" == "$alias_name" ]]; then
        lines+=("source \"$REPO_ROOT/$comp_path\"")
        break
      fi
    done
  done

  printf '%s\n' "${lines[@]}"
}

install_to_bashrc() {
  local new_block
  new_block=$(get_managed_block)

  # Remove old managed block if exists
  if grep -q "$MANAGED_START" "$RC" 2>/dev/null; then
    # Create temp file without managed block
    local tmp
    tmp=$(mktemp)
    awk -v start="$MANAGED_START" -v end="$MANAGED_END" '
      $0 == start { skip=1; next }
      $0 == end { skip=0; next }
      !skip { print }
    ' "$RC" > "$tmp"
    mv "$tmp" "$RC"
  fi

  # Add new managed block
  {
    echo ""
    echo "$MANAGED_START"
    echo "$new_block"
    echo "$MANAGED_END"
  } >> "$RC"
}

setup_tmux_config() {
  # Copy tmux config if tmux-setup is selected (tmux itself is installed via deps.sh)
  for item in "${SELECTED_ITEMS[@]}"; do
    IFS=: read -r type name path <<< "$item"
    if [[ "$name" == "tmux-setup" ]]; then
      local src="$REPO_ROOT/utilities/tmux_config/.tmux.conf"
      local dst="$HOME/.tmux.conf"

      # Backup existing config if present
      if [[ -f "$dst" ]]; then
        local backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
        mv "$dst" "$backup"
        echo "  ${YELLOW}!${RESET} Backed up existing ~/.tmux.conf"
      fi

      cp "$src" "$dst"
      echo "  ${GREEN}✓${RESET} tmux config"

      # Reload if running inside tmux
      if [[ -n "${TMUX:-}" ]]; then
        tmux source-file "$dst" 2>/dev/null || true
      fi
      return
    fi
  done
}

# ──────────────────────────────────────────────────────────────────────────────
# Install All (default)
# ──────────────────────────────────────────────────────────────────────────────

do_install_all() {
  build_available_list
  select_all

  echo ""
  echo "${BOLD}Unix System Utilities${RESET}"
  echo "────────────────────────────────────"
  echo ""
  echo "Installing:"
  for item in "${SELECTED_ITEMS[@]}"; do
    IFS=: read -r type name path <<< "$item"
    # Get description from original entry
    local desc=""
    if [[ "$type" == "alias" ]]; then
      for entry in "${AVAILABLE_ALIASES[@]}"; do
        IFS=: read -r ename epath edesc <<< "$entry"
        if [[ "$ename" == "$name" ]]; then
          desc="$edesc"
          break
        fi
      done
    else
      for entry in "${AVAILABLE_SOURCES[@]}"; do
        IFS=: read -r epath edesc <<< "$entry"
        local ename
        ename=$(basename "$(dirname "$epath")")
        if [[ "$ename" == "$name" ]]; then
          desc="$edesc (sourced)"
          break
        fi
      done
    fi
    printf "  %-12s - %s\n" "$name" "$desc"
  done

  # Show skipped utilities
  if [[ ${#SKIPPED_ALIASES[@]} -gt 0 ]]; then
    echo ""
    echo "Skipped (platform-specific):"
    for entry in "${SKIPPED_ALIASES[@]}"; do
      IFS=: read -r name desc plabel <<< "$entry"
      printf "  %-12s - %s\n" "$name" "$plabel"
    done
  fi

  # Collect utility directories for dependency check
  local -a util_dirs=()
  for item in "${SELECTED_ITEMS[@]}"; do
    IFS=: read -r type name path <<< "$item"
    util_dirs+=("$(get_util_dir "$path")")
  done

  # Check and install dependencies
  aggregate_deps "${util_dirs[@]}"
  local missing
  missing=$(check_missing_deps)
  if [[ -n "$missing" ]]; then
    install_deps "$missing"
  fi

  # Setup tmux config if selected (tmux installed via deps)
  setup_tmux_config

  # Install to bashrc
  echo ""
  echo "Writing to ~/.bashrc..."
  install_to_bashrc
  echo "  ${GREEN}✓${RESET} Done"

  # Source bashrc to activate aliases in this shell
  source "$RC"

  echo ""
  echo -n "source ~/.bashrc" | "$REPO_ROOT/utilities/copy_via_osc52/main.sh" 2>/dev/null
  echo "Run: ${BOLD}source ~/.bashrc${RESET} (copied to clipboard)"
}

# ──────────────────────────────────────────────────────────────────────────────
# Install with Selection (--select)
# ──────────────────────────────────────────────────────────────────────────────

do_install_select() {
  build_available_list
  show_selection_menu

  # Collect utility directories for dependency check
  local -a util_dirs=()
  for item in "${SELECTED_ITEMS[@]}"; do
    IFS=: read -r type name path <<< "$item"
    util_dirs+=("$(get_util_dir "$path")")
  done

  # Check and install dependencies
  aggregate_deps "${util_dirs[@]}"
  local missing
  missing=$(check_missing_deps)
  if [[ -n "$missing" ]]; then
    install_deps "$missing"
  fi

  # Setup tmux config if selected (tmux installed via deps)
  setup_tmux_config

  # Install to bashrc
  install_to_bashrc

  # Source bashrc to activate aliases in this shell
  source "$RC"

  echo ""
  log_success "Installation complete!"
  echo ""
  echo "Installed:"
  for item in "${SELECTED_ITEMS[@]}"; do
    IFS=: read -r type name path <<< "$item"
    echo "  - $name ($type)"
  done
  echo ""
  echo -n "source ~/.bashrc" | "$REPO_ROOT/utilities/copy_via_osc52/main.sh" 2>/dev/null
  echo "Run: ${BOLD}source ~/.bashrc${RESET} (copied to clipboard)"
}

# ──────────────────────────────────────────────────────────────────────────────
# List Utilities (--list)
# ──────────────────────────────────────────────────────────────────────────────

do_list() {
  echo ""
  echo "${BOLD}Available Utilities${RESET}"
  echo ""
  printf "  %-12s  %-40s  %s\n" "Alias" "Description" "Platform"
  echo "  ────────────  ────────────────────────────────────────  ────────────"

  for entry in "${ALIASES[@]}"; do
    IFS=: read -r name path desc platform <<< "$entry"
    local plabel
    plabel=$(platform_label "$platform")
    [[ -z "$plabel" ]] && plabel="all"
    printf "  %-12s  %-40s  %s\n" "$name" "$desc" "$plabel"
  done

  for entry in "${SOURCES[@]}"; do
    IFS=: read -r path desc platform <<< "$entry"
    local name
    name=$(basename "$(dirname "$path")")
    local plabel
    plabel=$(platform_label "$platform")
    [[ -z "$plabel" ]] && plabel="all"
    printf "  %-12s  %-40s  %s\n" "$name" "$desc (sourced)" "$plabel"
  done
  echo ""
}

# ──────────────────────────────────────────────────────────────────────────────
# Uninstall
# ──────────────────────────────────────────────────────────────────────────────

do_uninstall() {
  if grep -q "$MANAGED_START" "$RC" 2>/dev/null; then
    local tmp
    tmp=$(mktemp)
    awk -v start="$MANAGED_START" -v end="$MANAGED_END" '
      $0 == start { skip=1; next }
      $0 == end { skip=0; next }
      !skip { print }
    ' "$RC" > "$tmp"
    mv "$tmp" "$RC"
    log_success "Removed all unix_system_utilities from ~/.bashrc"

    # Reset prompt to default
    PS1='\u@\h:\w\$ '

    # Unalias installed commands
    for entry in "${ALIASES[@]}"; do
      IFS=: read -r name _ <<< "$entry"
      unalias "$name" 2>/dev/null || true
    done

    echo ""
    log_info "Open a new terminal for changes to fully take effect"
  else
    log_info "Nothing to uninstall"
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Help
# ──────────────────────────────────────────────────────────────────────────────

show_help() {
  cat <<EOF
Unix System Utilities Installer

Usage:
  ./install.sh              Install all compatible utilities + deps
  ./install.sh --select     Interactive numbered selection
  ./install.sh --list       Show available utilities table
  ./install.sh --uninstall  Remove from ~/.bashrc
  ./install.sh --help       Show this help
EOF
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

case "${1:-}" in
  --select)
    do_install_select
    ;;
  --list)
    do_list
    ;;
  --uninstall)
    do_uninstall
    ;;
  --help|-h)
    show_help
    ;;
  *)
    do_install_all
    ;;
esac
