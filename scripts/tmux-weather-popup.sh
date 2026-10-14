#!/usr/bin/env bash
set -u

location="${WEATHER_LOCATION:-$(tmux show-option -gqv @weather_location 2>/dev/null)}"
if [[ -z "$location" || "$location" == "YOUR_LOCATION" ]]; then
  echo 'Set @weather_location in ~/.config/tmux/local.conf to use the weather popup.'
else
  location=${location// /+}
  curl -s --max-time 10 "wttr.in/${location}?u"
fi
printf '\nPress any key to close.'
IFS= read -r -n 1 _ || true
