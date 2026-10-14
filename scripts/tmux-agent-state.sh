#!/usr/bin/env bash
# Record the current state for the agent in this tmux pane.

set -u

state=${1:-idle}
case "$state" in
  working|question|idle|error) ;;
  *) exit 0 ;;
esac

readonly DIR="${TMPDIR:-/tmp}/tmux-agent-anim-${UID}"
hook_meta=$(jq -r 'if type == "object" then [(.hook_event_name // ""), (.source // ""), (.notification_type // ""), (.tool_name // "")] | join("|") else "" end' 2>/dev/null || true)
hook_event_name=''
hook_source=''
notification_type=''
tool_name=''
IFS='|' read -r hook_event_name hook_source notification_type tool_name <<< "$hook_meta"

# Compaction continues the same turn. Keep its current indicator state.
[[ "$hook_event_name" != SessionStart || "$hook_source" != compact ]] || exit 0

# Question tools still need an answer when permission prompts are bypassed.
if [[ "$hook_event_name" == PreToolUse ]]; then
  case "$tool_name" in
    AskUserQuestion|ExitPlanMode|request_user_input) state=question ;;
  esac
fi

if [[ "$hook_event_name" == Notification ]]; then
  case "$notification_type" in
    permission_prompt|elicitation_dialog|elicitation_url_dialog|quota_auto_resume_stale) state=question ;;
    quota_auto_resume_fired) state=working ;;
    # Idle/auth alerts and background-agent notices do not change this turn.
    *) exit 0 ;;
  esac
fi

# A pane owns a hook only when its shell is an ancestor of that hook.
# Shared daemons can inherit stale or unrelated TMUX_PANE values. Neither those
# values, old guessed session routes, nor client focus establish ownership.
mapfile -t pane_rows < <(tmux list-panes -a -F '#{pane_id}|#{pane_pid}' 2>/dev/null)
pane=''
ancestor=$$
for ((depth = 0; depth < 32 && ancestor > 1; depth++)); do
  for row in "${pane_rows[@]}"; do
    [[ "${row#*|}" == "$ancestor" ]] || continue
    pane=${row%%|*}
    break
  done
  [[ -z "$pane" ]] || break
  parent=$(ps -o ppid= -p "$ancestor" 2>/dev/null) || break
  parent=${parent//[[:space:]]/}
  [[ "$parent" =~ ^[0-9]+$ && "$parent" != "$ancestor" ]] || break
  ancestor=$parent
done
[[ -n "$pane" ]] || exit 0
[[ "$pane" =~ ^%[0-9]+$ ]] || exit 0

state_dir="$DIR/state"
mkdir -p "$state_dir" 2>/dev/null || exit 0
printf '%s\n' "$state" > "$state_dir/${pane#%}"

"$HOME/.sh/tmux-agent-circle-animator.sh" >/dev/null 2>&1 &
