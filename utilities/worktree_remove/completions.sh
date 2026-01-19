#!/usr/bin/env bash
# Dynamic bash completions for rwt (worktree remove)

_rwt_completions() {
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || return

  local branches
  branches=$(git -C "$repo_root" worktree list --porcelain 2>/dev/null \
    | rg "^branch" \
    | sed 's|branch refs/heads/||')

  COMPREPLY=( $(compgen -W "$branches" -- "${COMP_WORDS[1]}") )
}
complete -F _rwt_completions rwt
