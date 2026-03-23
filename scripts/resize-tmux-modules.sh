#!/bin/bash
# Dynamically adjust tmux status-right modules based on terminal width.
# Uses catppuccin v2 status module format.

TINY_WIDTH=100
SMALL_WIDTH=105
MEDIUM_WIDTH=120
LARGE_WIDTH=140

# Get current terminal width
current_width=$(tmux display -p '#{window_width}')

# Build status-right based on width
SEP=''
BATT="#(${HOME}/.sh/tmux-battery-status.sh)"

# Smallest: just directory
modules='#{E:@catppuccin_status_directory}'

if [ "$current_width" -ge "$TINY_WIDTH" ]; then
        modules="#{E:@catppuccin_status_directory}"
fi

if [ "$current_width" -ge "$MEDIUM_WIDTH" ]; then
        modules="#{E:@catppuccin_status_directory}${SEP}#{E:@catppuccin_status_kubernetes}${SEP}${BATT}"
fi

if [ "$current_width" -ge "$LARGE_WIDTH" ]; then
        modules="#{E:@catppuccin_status_directory}${SEP}#{E:@catppuccin_status_kubernetes}${SEP}#{E:@catppuccin_status_podman}${SEP}${BATT}"
fi


# Wrap modules in default background
status_right="${modules}"

# Only update if changed to avoid unnecessary redraws
current_status=$(tmux show -gv status-right 2>/dev/null)
if [ "$current_status" != "$status_right" ]; then
	tmux set -g status-right "$status_right"
fi
