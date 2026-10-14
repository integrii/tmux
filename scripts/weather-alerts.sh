#!/usr/bin/env bash
# Print active NWS alerts for an optional point configured in local.conf.
set -u

POINT="${NWS_ALERT_POINT:-$(tmux show-option -gqv @weather_alert_point 2>/dev/null)}"
if [[ -z "$POINT" ]]; then
  echo 'Set @weather_alert_point to latitude,longitude in ~/.config/tmux/local.conf to enable local alerts.'
  exit 0
fi

bold=$'\e[1m'; amber=$'\e[38;5;215m'; blue=$'\e[38;5;111m'; dim=$'\e[2m'; reset=$'\e[0m'
body=$(curl -s --max-time 10 \
  -H "Accept: application/geo+json" \
  -H "User-Agent: tmux-weather-script" \
  "https://api.weather.gov/alerts/active?point=${POINT}")

if [[ -z "$body" ]] || ! jq -e '.features' >/dev/null 2>&1 <<< "$body"; then
  echo 'The NWS alert fetch failed.'
  echo
  echo "${blue}https://www.weather.gov/${reset}"
  exit 0
fi

count=$(jq '.features | length' <<< "$body")
echo "${bold}NWS weather alerts${reset} ${dim}(${count} active)${reset}"
echo
jq -r --arg bold "$bold" --arg amber "$amber" --arg dim "$dim" --arg reset "$reset" '
  .features[].properties |
  "\($amber)\($bold)󰀦 \(.event)\($reset)",
  (if .headline then "\($bold)\(.headline)\($reset)" else empty end),
  "\($dim)Severity: \(.severity // "")   Urgency: \(.urgency // "")\($reset)",
  "\($dim)From: \(.effective // "")   Until: \(.ends // .expires // "")\($reset)",
  "\($dim)Area: \(.areaDesc // "")\($reset)",
  "",
  (.description // ""),
  (if .instruction then "", "\($bold)Instructions\($reset)", .instruction else empty end),
  "",
  "\($dim)────────────────────────────────────────\($reset)",
  ""
' <<< "$body"
echo "Official NWS hazards page: ${blue}https://www.weather.gov/${reset}"
