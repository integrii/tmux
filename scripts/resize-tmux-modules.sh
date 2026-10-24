#!/bin/bash
# Keep status-right on the consolidated renderer.
# Width-based module selection happens inside tmux-status-right.sh.

# The animator publishes the slow renderer once a second. No #() job here:
# forced animation refreshes would restart it on every frame.
status_right='#{TMUX_AGENT_STATUS_RIGHT}'

# Only update if changed to avoid unnecessary redraws
current_status=$(tmux show -gv status-right 2>/dev/null)
if [ "$current_status" != "$status_right" ]; then
	tmux set -g status-right "$status_right"
fi
