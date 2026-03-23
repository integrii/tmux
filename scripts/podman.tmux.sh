#!/usr/bin/env bash
# this script displays podman machine info in the tmux status line
MACHINE=$(podman system connection list --format=json | jq '.[] | select(.Default == true ) | .Name' | cut -f2 -d\")

# if the podman machine is default, just echo "local" so we know its this machine
if [[ $MACHINE == "podman-machine-default" ]]; then
	echo "local"
else
	echo $MACHINE
fi


