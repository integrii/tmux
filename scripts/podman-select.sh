#!/usr/bin/env bash
# Pick the default podman connection with fzf, like kubectx does for kubernetes contexts.
# A connection is where podman sends commands: a local podman machine or a remote host over ssh.
# Add a remote with: podman system connection add <name> ssh://user@host/run/podman/podman.sock
# The tmux podman status click opens this script in a centered 50x20 popup.
set -u

connections=$(podman system connection list --format json 2>/dev/null |
	jq -r '.[] | [.Name, (if .IsMachine then "machine" else "remote" end), .URI, (if .Default then "*" else "" end)] | @tsv')

current=$(awk -F'\t' '$4 == "*" {print $1}' <<< "$connections")

choice=$(awk -F'\t' '{printf "%-30s %s\n", $1, $2}' <<< "$connections" |
	fzf --prompt 'podman> ' --header "current: ${current:-none}" --height 100% --reverse |
	awk '{print $1}')
[[ -z "$choice" ]] && exit 0

podman system connection default "$choice" || exit 1
echo "Switched to podman connection \"$choice\"."

rm -f /tmp/tmux_podman_status
tmux refresh-client -S 2>/dev/null || true
