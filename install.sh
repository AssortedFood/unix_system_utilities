#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────────────────────────────────
# Unix System Utilities - Interactive Installer
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
  log_warn "Missing dependencies: $missing"
  echo ""
  echo "Options:"
  echo "  y - Install all missing dependencies (requires sudo)"
  echo "  n - Skip (some utilities may not work)"
  echo "  m - Show manual installation commands"
  echo ""
  read -p "Install missing dependencies? [y/n/m] " -n 1 -r choice
  echo ""

  case "$choice" in
    [Yy])
      for cmd in $missing; do
        local install_cmd="${ALL_DEPS[$cmd]}"
        log_info "Installing $cmd..."
        eval "$install_cmd" || log_warn "Failed to install $cmd"
      done
      ;;
    [Mm])
      echo ""
      echo "Manual installation commands:"
      for cmd in $missing; do
        echo "  ${ALL_DEPS[$cmd]}"
      done
      echo ""
      ;;
    *)
      log_info "Skipping dependency installation"
      ;;
  esac
}

# ──────────────────────────────────────────────────────────────────────────────
# Interactive Selection
# ──────────────────────────────────────────────────────────────────────────────

declare -a AVAILABLE_ALIASES=()
declare -a AVAILABLE_SOURCES=()
declare -a SELECTED_ITEMS=()

build_available_list() {
  AVAILABLE_ALIASES=()
  AVAILABLE_SOURCES=()

  for entry in "${ALIASES[@]}"; do
    IFS=: read -r name path desc platform <<< "$entry"
    if matches_platform "$platform"; then
      AVAILABLE_ALIASES+=("$name:$path:$desc")
    fi
  done

  for entry in "${SOURCES[@]}"; do
    IFS=: read -r path desc platform <<< "$entry"
    if matches_platform "$platform"; then
      AVAILABLE_SOURCES+=("$path:$desc")
    fi
  done
}

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

do_install() {
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
  printf "Run %bsource ~/.bashrc%b to activate.\n" "${BLUE}" "${RESET}"
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
  else
    log_info "Nothing to uninstall"
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

show_help() {
  cat <<EOF
Unix System Utilities Installer

Usage:
  ./install.sh              Interactive installation
  ./install.sh --uninstall  Remove all utilities from ~/.bashrc
  ./install.sh --help       Show this help

To change your selection, run --uninstall then re-run the installer.
EOF
}

case "${1:-}" in
  --uninstall)
    do_uninstall
    ;;
  --help|-h)
    show_help
    ;;
  *)
    do_install
    ;;
esac
