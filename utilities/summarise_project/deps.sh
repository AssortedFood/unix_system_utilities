#!/usr/bin/env bash
# Dependencies for summarise_project

declare -A DEPS=(
  [fdfind]="apt install fd-find"
  [tree]="apt install tree"
  [rg]="apt install ripgrep"
)
