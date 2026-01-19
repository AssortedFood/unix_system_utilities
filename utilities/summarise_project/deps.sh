#!/usr/bin/env bash
# Dependencies for summarise_project

declare -A DEPS=(
  [fdfind]="apt install -y fd-find"
  [tree]="apt install -y tree"
  [rg]="apt install -y ripgrep"
)
