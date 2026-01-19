#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# WSL Bridge - Port forwarding from Windows host to WSL2
# Requires initial setup with: wsl-bridge --setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(wslpath "$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')")/.wsl-bridge"
TASK_NAME="WSL-PortForward"

show_help() {
    cat <<EOF
Usage: wsl-bridge [OPTIONS] [PORTS...]

Forward ports from Windows host to this WSL instance.

Options:
  --setup     Create the Windows scheduled task (requires UAC once)
  --status    Show current port forwarding rules
  --help      Show this help message

Examples:
  wsl-bridge --setup        # First-time setup (requires admin)
  wsl-bridge 2222           # Forward port 2222
  wsl-bridge 22 2222 8080   # Forward multiple ports
  wsl-bridge --status       # Show current rules

Note: Run --setup first before forwarding ports.
EOF
}

check_wsl() {
    if ! grep -qi Microsoft /proc/version 2>/dev/null; then
        echo "Error: This utility only works in WSL"
        exit 1
    fi
}

get_wsl_ip() {
    hostname -I | awk '{print $1}'
}

setup_scheduled_task() {
    echo "Setting up WSL-PortForward scheduled task..."

    # Create config directory in Windows
    mkdir -p "$CONFIG_DIR"

    # Copy PowerShell script to Windows
    cp "$SCRIPT_DIR/update-portproxy.ps1" "$CONFIG_DIR/"

    # Convert path to Windows format
    local ps_script_win
    ps_script_win="$(wslpath -w "$CONFIG_DIR/update-portproxy.ps1")"

    # Create the scheduled task with elevated privileges
    # This will trigger UAC once during setup
    powershell.exe -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -Command schtasks /Create /TN \"$TASK_NAME\" /TR \"powershell.exe -ExecutionPolicy Bypass -File \\\"$ps_script_win\\\"\" /SC ONCE /ST 00:00 /RL HIGHEST /F'"

    echo ""
    echo "Setup complete! The scheduled task has been created."
    echo "You can now run: wsl-bridge <port> [port...]"
}

check_task_exists() {
    if ! schtasks.exe /Query /TN "$TASK_NAME" &>/dev/null; then
        echo "Error: Scheduled task '$TASK_NAME' not found."
        echo "Please run 'wsl-bridge --setup' first."
        exit 1
    fi
}

show_status() {
    echo "Current port forwarding rules:"
    echo ""
    netsh.exe interface portproxy show v4tov4 2>/dev/null || echo "No rules configured"
}

forward_ports() {
    local ports=("$@")

    if [[ ${#ports[@]} -eq 0 ]]; then
        echo "Error: No ports specified"
        echo "Usage: wsl-bridge <port> [port...]"
        exit 1
    fi

    check_task_exists

    local ip
    ip=$(get_wsl_ip)

    echo "WSL IP: $ip"
    echo "Ports: ${ports[*]}"

    # Create config JSON
    local ports_json
    ports_json=$(printf '%s\n' "${ports[@]}" | jq -R . | jq -s .)

    local config_json
    config_json=$(jq -n --arg ip "$ip" --argjson ports "$ports_json" '{ip: $ip, ports: $ports}')

    # Write config file
    echo "$config_json" > "$CONFIG_DIR/config.json"

    # Trigger the scheduled task
    echo "Updating port forwarding..."
    schtasks.exe /Run /TN "$TASK_NAME" >/dev/null

    # Wait a moment for the task to complete
    sleep 2

    echo "Done! Port forwarding updated."
    echo ""
    show_status
}

# Main
check_wsl

case "${1:-}" in
    --setup)
        setup_scheduled_task
        ;;
    --status)
        show_status
        ;;
    --help|-h|"")
        show_help
        ;;
    *)
        forward_ports "$@"
        ;;
esac
