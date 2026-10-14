#!/bin/bash
# Detects AI tools/SSH running as a child of the pane shell.
# Sets @pane_icon window option (colored icon string) for use in window-status-format.
# Outputs a plain-text window name (no colors, no icon) for #W.
# Args: $1 = pane PID, $2 = pane_current_path, $3 = window_id,
#       $4 = pane_current_command
#
# Agent indicator colors live in ~/.sh/tmux-agent-circle-animator.sh. Keep any
# icon color here equal to that agent's idle color. question repeats the working
# color on a still disc. error is always red:
#
#   agent      working   idle      question  error
#   claude     #FF8A5B   #D97757   #FF8A5B   #EF4444
#   codex      #FFFFFF   #A1A1AA   #FFFFFF   #EF4444
#   opencode   #7DD3FC   #60A5FA   #7DD3FC   #EF4444
#   gemini     #C084FC   #A855F7   #C084FC   #EF4444
#   pi         #F9A8D4   #EC4899   #F9A8D4   #EF4444
#   other      #C4B5FD   #64748B   #C4B5FD   #EF4444
#
# AI harness panes use the agent circle animator for their pane icons.

[[ -z "$1" ]] && exit 0
source "$HOME/.sh/tmux-agent-name.sh"

win_id="$3"

pane_icon_for() {
  local pane_pid="$1" pane_command="$2" child_pid child_args agent
  agent=$(tmux_agent_name "$pane_pid") || agent=''
  case "$agent" in
    claude) printf '#[fg=#D97757]✳'; return ;;
    gemini) printf '#[fg=#A855F7]✦'; return ;;
    opencode) printf '#[fg=#60A5FA]󰅩'; return ;;
  esac
  child_pid=$(pgrep -P "$pane_pid" | head -1)
  child_args=""
  [[ -n "$child_pid" ]] && child_args=$(ps -o args= -p "$child_pid" 2>/dev/null)
  shopt -s nocasematch
  case "$child_args $pane_command" in
    *cliamp*)   printf '#[fg=#EF4444]󰝚' ;;
    *k9s*)      printf '#[fg=#116FE0]󰠳' ;;
    *btop*)     printf '#[fg=#BAE6FD]󰍛' ;;
    *ssh*)      printf '#[fg=#E2E8F0]󰒍' ;;
    *zsh*)      printf '#[fg=#94A3B8]' ;;
    *)          printf '#[fg=#94A3B8]󰆍' ;;
  esac
}

ensure_animator() {
  local owner='' owner_file="${TMPDIR:-/tmp}/tmux-agent-anim-${UID}/.circle-lock/pid"
  [[ ! -f "$owner_file" ]] || IFS= read -r owner < "$owner_file"
  [[ "$owner" =~ ^[0-9]+$ ]] && kill -0 "$owner" 2>/dev/null && return
  # One renderer owns every pane icon, including idle shells. A missed scan in
  # this title helper must not replace an animator frame with generic icons.
  "$HOME/.sh/tmux-agent-circle-animator.sh" </dev/null >/dev/null 2>&1 &
}

if [[ "$5" == "--icon-only" ]]; then
  pane_icon_for "$1" "$4"
  exit 0
fi

[[ -n "$win_id" ]] && ensure_animator

if [[ "$4" == "zsh" ]]; then
  [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#94A3B8]  "
  exit 0
fi

# Use pgrep to find direct children — avoids scanning all processes
child_pid=$(pgrep -P "$1" | head -1)

if [[ -z "$child_pid" ]]; then
  [[ -n "$win_id" ]] && tmux set-option -wuq -t "$win_id" @pane_icon 2>/dev/null
  exit 0
fi

# Get only args for the single child PID
child_args=$(ps -o args= -p "$child_pid" 2>/dev/null)
[[ -z "$child_args" ]] && exit 0

agent=$(tmux_agent_name "$1") || agent=''
case "$agent" in
  claude|codex)
    [[ -n "$win_id" ]] && tmux set-option -wuq -t "$win_id" @pane_icon 2>/dev/null
    basename "$2"; exit 0 ;;
  gemini)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#A855F7,bold]✦ "
    basename "$2"; exit 0 ;;
  opencode)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#60A5FA]󰅩  "
    basename "$2"; exit 0 ;;
esac

shopt -s nocasematch
case "$child_args" in
  *ssh*)
    hostname=$(echo "$child_args" | awk '{
      for (i=1; i<=NF; i++) {
        if ($i ~ /ssh$/) {
          for (j=i+1; j<=NF; j++) {
            if ($j ~ /^-/) {
              if ($j ~ /^-[bcDEeFiLlmoOpRSw]/) { j++; continue; }
              continue;
            }
            print $j; exit;
          }
        }
      }
    }')
    hostname=${hostname#*@}
    hostname=${hostname%/}
    hostname=${hostname:-ssh}
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#E2E8F0]󰒍  "
    echo "$hostname";;
  *btop*)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon " #[fg=#BAE6FD]󰍛" # keep the spacing in front for balancing without any title
    echo " ";;
  *cliamp*)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#EF4444]󰝚" # keep the spacing in front for balancing without any title
    echo " ";;
  *k9s*)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#116FE0]󰠳" # keep the font spacing in front for balancing without any title
    echo " ";;
  *)
    [[ -n "$win_id" ]] && tmux set-option -wuq -t "$win_id" @pane_icon 2>/dev/null
    ;;
esac
