#!/bin/bash
# Detects AI tools/SSH running as a child of the pane shell.
# Sets @pane_icon window option (colored icon string) for use in window-status-format.
# Outputs a plain-text window name (no colors, no icon) for #W.
# Args: $1 = pane PID, $2 = pane_current_path, $3 = window_id

[[ -z "$1" ]] && exit 0

win_id="$3"
child_info=$(ps -ax -o ppid=,comm=,args= | awk -v ppid="$1" '$1 == ppid {print $0; exit}')

if [[ -z "$child_info" ]]; then
  [[ -n "$win_id" ]] && tmux set-option -wuq -t "$win_id" @pane_icon 2>/dev/null
  exit 0
fi

child_args=$(echo "$child_info" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+[^[:space:]]+[[:space:]]+//')

case "$(echo "$child_args" | tr '[:upper:]' '[:lower:]')" in
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
  *claude*)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#D97757]󱙺  "
    basename "$2";;
  *codex*)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#F97316]󰧑  "
    basename "$2";;
  *gemini*)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#A855F7,bold]✦ "
    basename "$2";;
  *k9s*)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#326CE5]󰠳  "
    echo "k9s";;
  *opencode*)
    [[ -n "$win_id" ]] && tmux set-option -wq -t "$win_id" @pane_icon "#[fg=#60A5FA]󰅩  "
    basename "$2";;
  *)
    [[ -n "$win_id" ]] && tmux set-option -wuq -t "$win_id" @pane_icon 2>/dev/null
    ;;
esac
