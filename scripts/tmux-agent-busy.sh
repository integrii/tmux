#!/bin/bash
# Compatibility wrapper for older Codex and Claude hook configuration.
#
# Usage: tmux-agent-busy.sh busy|idle
#
case "${1:-}" in
  busy) exec "$HOME/.sh/tmux-agent-state.sh" working ;;
  idle) exec "$HOME/.sh/tmux-agent-state.sh" idle ;;
  *) exit 0 ;;
esac
