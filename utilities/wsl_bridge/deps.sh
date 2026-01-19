#!/usr/bin/env bash
# Dependencies for wsl_bridge

declare -A DEPS=(
  [jq]="apt install -y jq"
  [rg]="apt install -y ripgrep"
)
