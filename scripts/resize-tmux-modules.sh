#!/bin/bash
# Keep status-right on the consolidated renderer.
# Width-based module selection happens inside tmux-status-right.sh.

status_right="#(${HOME}/.sh/tmux-status-right.sh)"

# Only update if changed to avoid unnecessary redraws
current_status=$(tmux show -gv status-right 2>/dev/null)
if [ "$current_status" != "$status_right" ]; then
	tmux set -g status-right "$status_right"
fi
