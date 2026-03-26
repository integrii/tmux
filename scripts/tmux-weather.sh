#!/bin/bash
# Fetch weather for YOUR_LOCATION and return a color-coded tmux status string.
# Includes Day/Night logic based on sunset and moon phase icons.
# Caches rendered output (60s) to avoid re-parsing on every 1s status refresh.

CACHE_FILE="/tmp/tmux_weather_cache_YOUR_LOCATION"
RENDER_CACHE="/tmp/tmux_weather_render_YOUR_LOCATION"
CACHE_TTL=900   # 15 minutes — raw weather fetch
RENDER_TTL=60   # 60 seconds — rendered output (handles day/night transitions)

now_ts=$(date +%s)

# Return cached render if fresh enough
render_age=$(stat -f %m "$RENDER_CACHE" 2>/dev/null || echo 0)
if (( now_ts - render_age < RENDER_TTL )) && [[ -s "$RENDER_CACHE" ]]; then
  cat "$RENDER_CACHE"
  exit 0
fi

# Fetch new weather data if stale
last_fetch=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
if (( now_ts - last_fetch > CACHE_TTL )); then
  weather=$(curl -s --max-time 3 "wttr.in/YOUR_LOCATION?u&format=%c%t%S%s%m" | tr -d '+')
  if [[ -n "$weather" && ! "$weather" =~ "html" ]]; then
    echo "$weather" > "$CACHE_FILE"
  fi
fi

data=$(cat "$CACHE_FILE" 2>/dev/null)
arrow=$(printf '\xee\x82\xb0')
if [[ -z "$data" ]]; then
  tmux set -g @weather_bg "#89b4fa"
  tmux set -g @weather_sep_active "#[fg=#89b4fa,bg=#0060CC]${arrow}"
  tmux set -g @weather_sep_inactive "#[fg=#89b4fa,bg=#404040]${arrow}"
  printf "#[fg=#1e1e2e,bg=#89b4fa,bold] 󰖐 #[fg=#1e1e2e,bg=#89b4fa,nobold]--° "
  exit 0
fi

# Parse raw data
icon=$(echo "$data" | grep -oE '^[^0-9-]+' | sed 's/ *$//')
temp=$(echo "$data" | grep -oE '[-0-9]+°F')
times=$(echo "$data" | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}[0-9]{2}:[0-9]{2}:[0-9]{2}')
moon=$(echo "$data" | grep -oE '.$')

sunrise_str=${times:0:8}
sunset_str=${times:8:8}

today=$(date +%Y-%m-%d)
sunrise_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $sunrise_str" +%s 2>/dev/null)
sunset_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $sunset_str" +%s 2>/dev/null)

temp_clean="${temp%F}"

# Default: Neutral Sky Blue (Day)
bg_color="#89b4fa"
text_color="#1e1e2e"
display_icon="$icon"

# Day or Night logic
if [[ -n "$sunrise_ts" && -n "$sunset_ts" ]]; then
  if (( now_ts < sunrise_ts || now_ts > sunset_ts )); then
    # NIGHT TIME
    bg_color="#262626"
    text_color="#ffffff"
    display_icon="$moon"
  else
    # DAY TIME
    case "$icon" in
      "☀️")
        bg_color="#0080FF"; text_color="#ffffff";;
      "🌤️"|"⛅")
        bg_color="#74c7ec"; text_color="#ffffff";;
      "☁️"|"󰖐"|"🌥️")
        bg_color="#94e2d5"; text_color="#1e1e2e";;
      "🌦️"|"☁️")
        bg_color="#bac2de"; text_color="#1e1e2e";;
      "🌧️"|"🌨️"|"❄️"|"󰼶")
        bg_color="#6c7086"; text_color="#ffffff";;
      "⛈️")
        bg_color="#313244"; text_color="#ffffff";;
    esac
  fi
fi

tmux set -g @weather_bg "$bg_color"
tmux set -g @weather_sep_active "#[fg=$bg_color,bg=#0060CC]${arrow}"
tmux set -g @weather_sep_inactive "#[fg=$bg_color,bg=#404040]${arrow}"
output=$(printf "#[fg=%s,bg=%s,bold] %s #[fg=%s,bg=%s,nobold]%s " "$text_color" "$bg_color" "$display_icon" "$text_color" "$bg_color" "$temp_clean")

# Cache rendered output
echo -n "$output" > "$RENDER_CACHE"
echo -n "$output"
