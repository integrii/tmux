#!/bin/bash
set -u

width="$(tmux display-message -p '#{window_width}' 2>/dev/null || echo 120)"
directory="$(tmux display-message -p '#{b:pane_current_path}' 2>/dev/null || echo '')"
now_ts="$(date +%s)"

status_name() {
	local name="$1" module="$2" until range
	until="$(tmux show-option -gqv "@${module}_reveal_until" 2>/dev/null)"
	if [[ "$until" =~ ^[0-9]+$ ]] && (( now_ts < until )); then
		range="${module}-full"
	else
		range="$module"
		if (( ${#name} > 25 )); then
			name="${name:0:9}…${name: -10}"
		fi
	fi
	printf '#[range=user|%s]%s' "$range" "$name"
}

cache_fresh() {
	local file="$1"
	local ttl="$2"
	local age
	age="$(stat -f %m "$file" 2>/dev/null || echo 0)"
	(( now_ts - age < ttl )) && [[ -s "$file" ]]
}

cached_cmd() {
	local cache="$1"
	local ttl="$2"
	shift 2
	if cache_fresh "$cache" "$ttl"; then
		cat "$cache"
		return 0
	fi
	"$@" > "$cache.tmp" 2>/dev/null || true
	mv "$cache.tmp" "$cache" 2>/dev/null || true
	cat "$cache" 2>/dev/null || true
}

kube_status() {
	cached_cmd /tmp/tmux_kubectl_status 30 "$HOME/.sh/kubectl.tmux.sh"
}

podman_status() {
	cached_cmd /tmp/tmux_podman_status 30 "$HOME/.sh/podman.tmux.sh"
}

battery_status() {
	cached_cmd /tmp/tmux_battery_status 15 "$HOME/.sh/tmux-battery-status.sh"
}

# The directory user range is clickable; MouseDown1Status in tmux.conf opens the pane directory with open.
printf '#[range=user|directory]#[fg=#D75F00,bg=default]  #[fg=#C0C0C0,bg=default]%s#[norange]' "$directory"

if (( width >= 120 )); then
	# A first click reveals the name; the full-name range opens the picker.
	kube="$(kube_status)"
	printf '#[fg=#0080FF,bg=default] 󰠳#[fg=#C0C0C0,bg=default] %s#[norange] 󰿠 #[range=user|kube-ns]%s#[norange]' \
		"$(status_name "${kube%% 󰿠 *}" kube)" "${kube#* 󰿠 }"
fi

if (( width >= 140 )); then
	printf '#[fg=#fab387,bg=default] 󰮄#[fg=#C0C0C0,bg=default] %s#[norange]' "$(status_name "$(podman_status)" podman)"
fi

if (( width >= 120 )); then
	# The battery user range is clickable; MouseDown1Status in tmux.conf opens btop in a full-screen popup.
	battery="$(battery_status)"
	[[ -n "$battery" ]] && printf '#[range=user|battery]%s#[norange]' "$battery"
fi
