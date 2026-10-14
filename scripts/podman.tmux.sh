#!/usr/bin/env bash
# this script displays podman machine info in the tmux status line
set -u

STATUS_CACHE="${PODMAN_TMUX_STATUS_CACHE:-/tmp/tmux_podman_status}"
STATUS_TTL="${PODMAN_TMUX_STATUS_TTL:-30}"
now_ts=$(date +%s)

cache_age=$(stat -f %m "$STATUS_CACHE" 2>/dev/null || echo 0)
if (( now_ts - cache_age < STATUS_TTL )) && [[ -s "$STATUS_CACHE" ]]; then
	cat "$STATUS_CACHE"
	exit 0
fi

MACHINE=$(podman system connection list --format=json 2>/dev/null | jq '.[] | select(.Default == true ) | .Name' | cut -f2 -d\")

# if the podman machine is default, just echo "local" so we know its this machine
if [[ $MACHINE == "podman-machine-default" ]]; then
	output="local"
else
	output="$MACHINE"
fi

printf '%s' "$output" > "$STATUS_CACHE"
printf '%s' "$output"
