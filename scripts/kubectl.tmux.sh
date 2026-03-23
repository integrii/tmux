#!/usr/bin/env bash
SYSTEM_SERIAL="$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')"
export KUBECONFIG="$HOME/.kube/config.$SYSTEM_SERIAL"

echo "`kubectx -c` 󰿠 `kubens -c`"
#echo $KUBECONFIG
