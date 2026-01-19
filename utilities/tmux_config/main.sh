#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# tmux-setup: Install tmux and symlink configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONF="$SCRIPT_DIR/.tmux.conf"
TARGET="$HOME/.tmux.conf"

# Check if tmux is installed
if ! command -v tmux &>/dev/null; then
    echo "tmux is not installed. Installing..."
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y tmux
    elif command -v brew &>/dev/null; then
        brew install tmux
    elif command -v pkg &>/dev/null; then
        pkg install tmux
    else
        echo "Error: Could not detect package manager. Please install tmux manually."
        exit 1
    fi
    echo "tmux installed successfully."
fi

# Backup existing config if it exists and is not a symlink
if [[ -f "$TARGET" && ! -L "$TARGET" ]]; then
    BACKUP="$TARGET.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing config to $BACKUP"
    mv "$TARGET" "$BACKUP"
elif [[ -L "$TARGET" ]]; then
    echo "Removing existing symlink..."
    rm "$TARGET"
fi

# Create symlink
echo "Creating symlink: $TARGET -> $TMUX_CONF"
ln -s "$TMUX_CONF" "$TARGET"

echo "Done! tmux config installed."
echo "Run 'tmux source-file ~/.tmux.conf' to reload in an existing session."
