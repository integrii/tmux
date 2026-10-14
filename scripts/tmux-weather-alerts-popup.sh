#!/usr/bin/env bash
# Open weather-alerts.sh in a centered tmux popup, 90 cols wide.
# The height is 45% of the client (about 27% free above and below), with a max of 75 rows.
# tmux does not expand formats in display-popup -h, so this script calculates the height.
set -u

client="${1:-}"
height=$(tmux display -p ${client:+-c "$client"} '#{client_height}')
height=$(( height * 45 / 100 ))
(( height > 75 )) && height=75

tmux display-popup ${client:+-c "$client"} -E -x C -y C -w 90 -h "$height" -s bg=#000000 -T ' NWS alerts ' \
	"$HOME/.sh/weather-alerts.sh | less -R -P 'Press q to close.'"
