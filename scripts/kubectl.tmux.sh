#!/usr/bin/env bash
set -u

STATUS_CACHE="${KUBECTL_TMUX_STATUS_CACHE:-/tmp/tmux_kubectl_status}"
STATUS_TTL="${KUBECTL_TMUX_STATUS_TTL:-30}"
now_ts=$(date +%s)

cache_age=$(stat -f %m "$STATUS_CACHE" 2>/dev/null || echo 0)
if (( now_ts - cache_age < STATUS_TTL )) && [[ -s "$STATUS_CACHE" ]]; then
  cat "$STATUS_CACHE"
  exit 0
fi

context="$(kubectx -c 2>/dev/null)"
namespace="$(kubens -c 2>/dev/null)"
output="$(printf '%s 󰿠 %s' "$context" "$namespace")"
printf '%s' "$output" > "$STATUS_CACHE"
printf '%s' "$output"
