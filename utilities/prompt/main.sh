# Custom bash prompt with git integration
# This file is meant to be sourced, not executed

# Config
PROMPT_PATH_SEGMENTS=3  # Number of visible path segments to keep
export VIRTUAL_ENV_DISABLE_PROMPT=1  # We handle venv display ourselves

format_time() {
  local t=$1
  if (( t < 60 )); then
    echo "${t}s"
  elif (( t < 3600 )); then
    echo "$((t / 60))m $((t % 60))s"
  else
    echo "$((t / 3600))h $(((t % 3600) / 60))m"
  fi
}

git_status_color() {
  local status=$(git status --porcelain 2>/dev/null)

  if [[ -n "$status" ]]; then
    if echo "$status" | rg -q '^.?[MD]'; then
      echo "33"  # yellow — modified
    else
      echo "32"  # green — untracked only
    fi
    return
  fi

  # Clean working tree — check if ahead of remote
  local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)

  if [[ -n "$ahead" && "$ahead" -gt 0 ]]; then
    echo "37"        # white — ahead, need to push
  else
    echo "38;5;245"  # grey — in sync
  fi
}

truncate_path() {
  local path="$1"
  local max_segments="$PROMPT_PATH_SEGMENTS"

  local prefix=""
  local working_path="$path"

  if [[ "$path" == "~"* ]]; then
    prefix="~"
    working_path="${path#\~}"
  fi

  working_path="${working_path#/}"
  local parts=()
  IFS='/' read -ra parts <<< "$working_path"

  local count=${#parts[@]}

  if (( count <= max_segments )); then
    echo "$path"
    return
  fi

  local result="${prefix}/…"
  for (( i = count - max_segments; i < count; i++ )); do
    result="${result}/${parts[i]}"
  done

  echo "$result"
}

path_prompt() {
  local full_path="$PWD"
  [[ "$full_path" == "$HOME"* ]] && full_path="~${full_path#$HOME}"

  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "$branch" || -z "$git_root" ]]; then
    echo -e "$(truncate_path "$full_path")"
    return
  fi

  local git_root_name="${git_root##*/}"
  local git_root_display="$git_root"
  [[ "$git_root_display" == "$HOME"* ]] && git_root_display="~${git_root_display#$HOME}"

  local truncated=$(truncate_path "$full_path")

  # Transform branch: feature/some-feature -> feature-some-feature
  local branch_as_dir="${branch//\//-}"

  if [[ "$git_root_name" == "$branch_as_dir" && "$truncated" == *"/$git_root_name"* ]]; then
    local color=$(git_status_color)
    local before="${truncated%/$git_root_name*}"
    local after="${truncated#*$git_root_name}"
    echo -e "${before}/\e[${color}m${git_root_name}\e[38;5;245m${after}"
  else
    local color=$(git_status_color)
    echo -e "${truncated} \e[${color}m${branch}"
  fi
}

timer_prompt() {
  local t=${timer_show:-0}
  (( t <= 3 )) && return

  local color
  if (( t < 60 )); then
    color="32"            # green — under 1m
  elif (( t < 300 )); then
    color="33"            # yellow — 1-5m
  else
    color="31"            # red — over 5m
  fi

  echo -e " \e[${color}m$(format_time $t)"
}

prompt_char_color() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "37"  # white when in venv
  else
    echo "38;5;245"  # grey normally
  fi
}

trap '[[ -z "${COMP_LINE:-}" ]] && timer_start=${timer_start:-$SECONDS}' DEBUG
PROMPT_COMMAND='timer_show=$((SECONDS - ${timer_start:-$SECONDS})); unset timer_start'

PS1='$([ $? -ne 0 ] && echo "\[\e[31m\]! ")\[\e[38;5;245m\]$(path_prompt)\[\e[90m\]$([ \j -gt 0 ] && echo " [\j]")$(timer_prompt)\[\e[0m\]\n\[\e[$(prompt_char_color)m\]❯\[\e[0m\] '
