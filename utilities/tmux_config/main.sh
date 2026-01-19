#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# tmux-setup: Install tmux and copy configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONF="$SCRIPT_DIR/.tmux.conf"
TARGET="$HOME/.tmux.conf"

# Check if tmux is installed
if ! command -v tmux &>/dev/null; then
    echo "tmux is not installed. Installing..."
    if [[ $EUID -ne 0 ]]; then
        sudo apt install -y tmux
    else
        apt install -y tmux
    fi
    echo "tmux installed successfully."
fi

# Backup existing config if it exists
if [[ -f "$TARGET" ]]; then
    BACKUP="$TARGET.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing config to $BACKUP"
    mv "$TARGET" "$BACKUP"
fi

# Copy config
echo "Installing tmux config to $TARGET"
cp "$TMUX_CONF" "$TARGET"

echo "Done! tmux config installed."

# Reload if running inside tmux
if [[ -n "${TMUX:-}" ]]; then
    tmux source-file ~/.tmux.conf
    echo "Reloaded tmux config."
fi
