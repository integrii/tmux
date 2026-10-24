#!/usr/bin/env bash
# Render one colored state indicator per agent pane in each tmux window.

set -u
shopt -s nullglob nocasematch
source "$HOME/.sh/tmux-agent-name.sh"
# Homebrew Bash ships a fractional sleep builtin. Avoid spawning /bin/sleep
# for every frame (its process startup also makes a 40ms frame miss its budget).
enable -f "${BASH%/bin/bash}/lib/bash/sleep" sleep 2>/dev/null || true

readonly DIR="${TMPDIR:-/tmp}/tmux-agent-anim-${UID}"
readonly STATE_DIR="$DIR/state"
readonly LOCK="$DIR/.circle-lock"
readonly LOCK_OWNER="$LOCK/pid"
# 25 frames per second. Process discovery and status commands run once a second.
readonly FRAME_MICROSECONDS=40000
readonly IDLE_SECONDS=1
readonly RESCAN_SECONDS=1
# Nerd Fonts weather moon_alt glyphs: one full lunar cycle, new to waning crescent.
readonly FRAMES=("" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "")

# Indicator colors. The agent picks the hue. The working color is always
# brighter than the idle color. question uses a question-mark circle in the
# working color, so a wait for an answer is distinct from idle. error is always red,
# so an alert looks the same whatever raised it.
#
#   agent      working   idle      question  error
#   claude     #FF8A5B   #D97757   #FF8A5B   #EF4444
#   codex      #FFFFFF   #A1A1AA   #FFFFFF   #EF4444
#   opencode   #7DD3FC   #60A5FA   #7DD3FC   #EF4444
#   gemini     #C084FC   #A855F7   #C084FC   #EF4444
#   pi         #F9A8D4   #EC4899   #F9A8D4   #EF4444
#   other      #C4B5FD   #64748B   #C4B5FD   #EF4444
declare -rA WORKING_FG=(
  [claude]='#FF8A5B'
  [codex]='#FFFFFF'
  [opencode]='#7DD3FC'
  [gemini]='#C084FC'
  [pi]='#F9A8D4'
  [other]='#C4B5FD'
)
declare -rA IDLE_FG=(
  [claude]='#D97757'
  [codex]='#A1A1AA'
  [opencode]='#60A5FA'
  [gemini]='#A855F7'
  [pi]='#EC4899'
  [other]='#64748B'
)
readonly ERROR_FG='#EF4444'

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
if [[ -d "$LOCK" ]]; then
  owner=''
  [[ -f "$LOCK_OWNER" ]] && IFS= read -r owner < "$LOCK_OWNER"
  # A new owner creates the directory before publishing its PID. Let it finish.
  [[ "$owner" =~ ^[0-9]+$ ]] || exit 0
  if ! kill -0 "$owner" 2>/dev/null; then
    rm -f "$LOCK_OWNER"
    rmdir "$LOCK" 2>/dev/null || exit 0
  else
    exit 0
  fi
fi
mkdir "$LOCK" 2>/dev/null || exit 0
printf '%s\n' "$$" > "$LOCK_OWNER"
cleanup() {
  if [[ -n ${scan_pid:-} ]]; then
    kill "$scan_pid" 2>/dev/null || true
    wait "$scan_pid" 2>/dev/null || true
  fi
  rm -f "$LOCK/scan"
  rm -f "$LOCK_OWNER"
  rmdir "$LOCK" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 0' INT TERM HUP

# weather-moon_alt_new: the solid disc of the animation set. In this set ink
# means shadow, so "new" is the filled circle and "full" is the empty outline.
readonly FULL_MOON=""

# Renders one indicator into $circle_out. Avoids a subshell per pane per frame.
circle() {
  local state=$1 frame=$2 agent=$3
  case "$state" in
    working) circle_out="#[fg=${WORKING_FG[$agent]:-${WORKING_FG[other]}}]${FRAMES[frame]}" ;;
    question) circle_out="#[fg=${WORKING_FG[$agent]:-${WORKING_FG[other]}}]" ;;
    error) circle_out="#[fg=$ERROR_FG]$FULL_MOON" ;;
    *) circle_out="#[fg=${IDLE_FG[$agent]:-${IDLE_FG[other]}}]$FULL_MOON" ;;
  esac
}

frame=0
declare -A agent_cache=()
declare -A pane_icon_cache=()
# Avoid pane-border redraws when an indicator has not changed.
declare -A last_pane_indicators=()
declare -A last_pane_agents=()
declare -A last_window_icons=()
declare -a client_targets=()
status_left=''
status_right=''
last_status_left=''
last_status_right=''
mapfile -t pane_rows < <(tmux list-panes -a -F '#{window_id}|#{pane_id}|#{pane_pid}|#{pane_current_command}' 2>/dev/null)

# Process discovery is slower than a frame. Run it separately so ps/pgrep and
# non-agent icon lookups cannot pause the animation once per scan.
scan_panes() {
  local row window_id rest pane_id pane_pid pane_command key agent icon
  for row in "${pane_rows[@]}"; do
    window_id=${row%%|*}
    rest=${row#*|}
    pane_id=${rest%%|*}
    rest=${rest#*|}
    pane_pid=${rest%%|*}
    pane_command=${rest#*|}
    key="$pane_id:$pane_pid:$pane_command"
    agent=$(tmux_agent_name "$pane_pid") || agent=''
    icon=''
    if [[ -z "$agent" ]]; then
      icon=$("$HOME/.sh/tmux-pane-icon.sh" "$pane_pid" "" "$window_id" "$pane_command" --icon-only)
    fi
    printf '%s|%s|%s\n' "$key" "$agent" "$icon"
  done
  # refresh-client -S forces every #() job to restart. Keep those commands
  # off the animation path so weather/context/battery work cannot run at 25 Hz.
  printf '__status_left||%s\n' "$("$HOME/.sh/tmux-weather.sh")"
  printf '__status_right||%s\n' "$("$HOME/.sh/tmux-status-right.sh")"
  while IFS= read -r client; do
    [[ -z "$client" ]] || printf '__client||%s\n' "$client"
  done < <(tmux list-clients -F '#{client_name}' 2>/dev/null)
}

load_scan() {
  local key agent icon
  agent_cache=()
  pane_icon_cache=()
  client_targets=()
  while IFS='|' read -r key agent icon; do
    case "$key" in
      __status_left) status_left=$icon; continue ;;
      __status_right) status_right=$icon; continue ;;
      __client) client_targets+=("$icon"); continue ;;
    esac
    agent_cache[$key]=$agent
    pane_icon_cache[$key]=$icon
  done < "$LOCK/scan"
}

# Discover the first set before painting, then retain it during background scans.
scan_pid=''
scan_panes > "$LOCK/scan"
load_scan
next_scan=$((SECONDS + RESCAN_SECONDS))
next_frame=${EPOCHREALTIME/./}
while :; do
  frame_started=${EPOCHREALTIME/./}
  # Keep deadlines on a fixed clock so timer overshoot does not lower the FPS.
  # After a longer pause, start fresh instead of racing through missed frames.
  if (( frame_started > next_frame + FRAME_MICROSECONDS )); then
    next_frame=$frame_started
  fi
  owner=''
  [[ -f "$LOCK_OWNER" ]] && IFS= read -r owner < "$LOCK_OWNER"
  [[ "$owner" == "$$" ]] || exit 0

  declare -A seen_panes=()
  declare -A seen_windows=()
  declare -A pane_indicators=()
  declare -A pane_agents=()
  declare -A window_icons=()
  working=0

  for row in "${pane_rows[@]}"; do
    window_id=${row%%|*}
    rest=${row#*|}
    pane_id=${rest%%|*}
    rest=${rest#*|}
    pane_pid=${rest%%|*}
    pane_command=${rest#*|}
    seen_panes[$pane_id]=1
    seen_windows[$window_id]=1
    key="$pane_id:$pane_pid:$pane_command"
    agent=${agent_cache[$key]:-}
    pane_agents[$pane_id]=$agent

    if [[ -n "$agent" ]]; then
      state=idle
      [[ -f "$STATE_DIR/${pane_id#%}" ]] && IFS= read -r state < "$STATE_DIR/${pane_id#%}"
      circle "$state" "$frame" "$agent"
      pane_indicators[$pane_id]=$circle_out
      [[ "$state" == working ]] && ((working++))
    else
      pane_indicators[$pane_id]=${pane_icon_cache[$key]:-}
    fi
    window_icons[$window_id]="${window_icons[$window_id]:+${window_icons[$window_id]} }${pane_indicators[$pane_id]:-}"
  done

  for pane_id in "${!last_pane_indicators[@]}"; do
    [[ -n ${seen_panes[$pane_id]:-} ]] && continue
    tmux set-environment -gu "TMUX_AGENT_PANE_${pane_id#%}" 2>/dev/null
    unset 'last_pane_indicators[$pane_id]' 'last_pane_agents[$pane_id]'
  done
  for window_id in "${!last_window_icons[@]}"; do
    [[ -n ${seen_windows[$window_id]:-} ]] && continue
    tmux set-environment -gu "TMUX_AGENT_WINDOW_${window_id#@}" 2>/dev/null
    unset 'last_window_icons[$window_id]'
  done

  for state_file in "$STATE_DIR"/[0-9]*; do
    pane_id="%${state_file##*/}"
    [[ -n ${seen_panes[$pane_id]:-} ]] || rm -f "$state_file"
  done

  # User-option changes redraw every pane and popup. Keep a stable format reference
  # and animate hidden environment values, which only need a status refresh.
  commands=(list-panes -a -F '#{window_id}|#{pane_id}|#{pane_pid}|#{pane_current_command}')
  if [[ "$status_left" != "$last_status_left" ]]; then
    commands+=(';' set-environment -gh TMUX_AGENT_STATUS_LEFT "$status_left")
    last_status_left=$status_left
  fi
  if [[ "$status_right" != "$last_status_right" ]]; then
    commands+=(';' set-environment -gh TMUX_AGENT_STATUS_RIGHT "$status_right")
    last_status_right=$status_right
  fi
  for window_id in "${!seen_windows[@]}"; do
    if [[ ! -v last_window_icons[$window_id] || ${last_window_icons[$window_id]} != "${window_icons[$window_id]:-}" ]]; then
      if [[ ! -v last_window_icons[$window_id] ]]; then
        commands+=(';' set-option -w -t "$window_id" @pane_icons "#{TMUX_AGENT_WINDOW_${window_id#@}}")
      fi
      commands+=(';' set-environment -gh "TMUX_AGENT_WINDOW_${window_id#@}" "${window_icons[$window_id]:-}")
      last_window_icons[$window_id]=${window_icons[$window_id]:-}
    fi
  done
  for pane_id in "${!seen_panes[@]}"; do
    if [[ ! -v last_pane_agents[$pane_id] || ${last_pane_agents[$pane_id]} != "${pane_agents[$pane_id]:-}" ]]; then
      if [[ -n ${pane_agents[$pane_id]:-} ]]; then
        commands+=(';' set-option -p -t "$pane_id" @pane_agent "${pane_agents[$pane_id]}")
      else
        commands+=(';' set-option -pu -t "$pane_id" @pane_agent)
      fi
      last_pane_agents[$pane_id]=${pane_agents[$pane_id]:-}
    fi
    if [[ ! -v last_pane_indicators[$pane_id] || ${last_pane_indicators[$pane_id]} != "${pane_indicators[$pane_id]:-}" ]]; then
      if [[ ! -v last_pane_indicators[$pane_id] ]]; then
        commands+=(';' set-option -p -t "$pane_id" @pane_indicator "#{TMUX_AGENT_PANE_${pane_id#%}}")
      fi
      commands+=(';' set-environment -gh "TMUX_AGENT_PANE_${pane_id#%}" "${pane_indicators[$pane_id]:-}")
      last_pane_indicators[$pane_id]=${pane_indicators[$pane_id]:-}
    fi
  done
  if (( ${#commands[@]} > 5 )); then
    for client in "${client_targets[@]}"; do
      commands+=(';' refresh-client -S -t "$client")
    done
  fi
  mapfile -t pane_rows < <(tmux "${commands[@]}" 2>/dev/null)
  (( ${#pane_rows[@]} > 0 )) || exit 0

  if [[ -n "$scan_pid" ]] && ! kill -0 "$scan_pid" 2>/dev/null; then
    if wait "$scan_pid"; then load_scan; fi
    scan_pid=''
    next_scan=$((SECONDS + RESCAN_SECONDS))
  fi
  if [[ -z "$scan_pid" ]] && (( SECONDS >= next_scan )); then
    scan_panes > "$LOCK/scan" &
    scan_pid=$!
  fi

  frame=$(( (frame + 1) % ${#FRAMES[@]} ))
  if (( working > 0 )); then
    next_frame=$((next_frame + FRAME_MICROSECONDS))
    remaining=$((next_frame - ${EPOCHREALTIME/./}))
    if (( remaining > 0 )); then
      printf -v frame_delay '0.%06d' "$remaining"
      sleep "$frame_delay"
    fi
  else
    # Keep one owner alive so a hook cannot lose its start during idle shutdown.
    sleep "$IDLE_SECONDS"
    next_frame=${EPOCHREALTIME/./}
  fi
done
