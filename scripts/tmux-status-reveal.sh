#!/usr/bin/env bash
set -eu

case "${1:-}" in
  kube|podman) ;;
  *) exit 1 ;;
esac

tmux set-option -g "@${1}_reveal_until" "$(($(date +%s) + 5))"
tmux refresh-client -S
