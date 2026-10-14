# Sourced helper. tmux_agent_name PANE_PID prints the AI agent name (claude,
# codex, gemini, opencode, pi) found among the pane's child processes, or
# returns 1 if none. Checks the pane process (exec'd agents), children, and
# grandchildren to catch wrappers.
tmux_agent_name() {
  local pane_pid="$1" pid line name
  [[ -n "$pane_pid" ]] || return 1
  local -a pgrep_options=()
  [[ "$OSTYPE" != darwin* ]] || pgrep_options=(-a)
  for pid in "$pane_pid" $(pgrep "${pgrep_options[@]}" -P "$pane_pid") $(pgrep "${pgrep_options[@]}" -P "$pane_pid" | xargs -I{} pgrep "${pgrep_options[@]}" -P {} 2>/dev/null); do
    line=$(ps -o args= -p "$pid" 2>/dev/null) || continue
    line=${line%% *}; line=${line##*/}
    case "$line" in
      claude*) name=claude ;;
      codex*)           name=codex ;;
      gemini*)          name=gemini ;;
      opencode*)        name=opencode ;;
      pi)               name=pi ;;
      *)                 continue ;;
    esac
    printf '%s\n' "$name"
    return 0
  done
  return 1
}
