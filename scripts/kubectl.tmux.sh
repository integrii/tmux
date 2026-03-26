#!/usr/bin/env bash
# Cache serial number — it never changes
SERIAL_CACHE="/tmp/tmux_hw_serial"
if [[ -f "$SERIAL_CACHE" ]]; then
  SYSTEM_SERIAL=$(<"$SERIAL_CACHE")
else
  SYSTEM_SERIAL=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
  echo "$SYSTEM_SERIAL" > "$SERIAL_CACHE"
fi
export KUBECONFIG="$HOME/.kube/config.$SYSTEM_SERIAL"

echo "$(kubectx -c) 󰿠 $(kubens -c)"
