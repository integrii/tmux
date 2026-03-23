#!/bin/bash
# Fetch weather for 98332 and return a color-coded tmux status string.
# Includes Day/Night logic based on sunset and moon phase icons.

CACHE_FILE="/tmp/tmux_weather_cache_98332"
CACHE_TTL=900 # 15 minutes

now_ts=$(date +%s)
last_fetch=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)

if (( now_ts - last_fetch > CACHE_TTL )); then
  # Fetch format: Icon(c) Temp(t) Sunrise(S) Sunset(s) Moon(m)
  # Example output: ☀️+48°F07:07:0119:26:38🌒
  weather=$(curl -s "wttr.in/98332?u&format=%c%t%S%s%m" | tr -d '+')
  if [[ -n "$weather" && ! "$weather" =~ "html" ]]; then
    echo "$weather" > "$CACHE_FILE"
  fi
fi

data=$(cat "$CACHE_FILE" 2>/dev/null)
if [[ -z "$data" ]]; then
  printf "#[fg=#1e1e2e,bg=#89b4fa,bold] 󰖐 #[fg=#1e1e2e,bg=#89b4fa,nobold]--° #[fg=#89b4fa,bg=#000000]"
  exit 0
fi

# Parsing the data string
# We know: Icon(1-2 chars), Temp(N°F), Sunrise(HH:MM:SS), Sunset(HH:MM:SS), Moon(1 char)
# wttr.in format is a bit compressed, so we use regex or fixed positions if possible
icon=$(echo "$data" | grep -oE '^[^0-9-]+')
temp=$(echo "$data" | grep -oE '[-0-9]+°F')
times=$(echo "$data" | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}[0-9]{2}:[0-9]{2}:[0-9]{2}')
moon=$(echo "$data" | grep -oE '.$')

sunrise_str=${times:0:8}
sunset_str=${times:8:8}

# Convert sunrise/sunset to timestamps for comparison
today=$(date +%Y-%m-%d)
sunrise_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $sunrise_str" +%s 2>/dev/null)
sunset_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $sunset_str" +%s 2>/dev/null)

# Drop 'F' from temp
temp_clean="${temp%F}"

# Default: Neutral Sky Blue (Day)
bg_color="#89b4fa"
text_color="#1e1e2e"
display_icon="$icon"

# Day or Night logic
if [[ -n "$sunrise_ts" && -n "$sunset_ts" ]]; then
  if (( now_ts < sunrise_ts || now_ts > sunset_ts )); then
    # NIGHT TIME
    bg_color="#262626" # Dark grey background for night contrast
    text_color="#ffffff" # White text for contrast
    display_icon="$moon" # Use the moon phase
  else
    # DAY TIME - use sky gradient logic
    case "$icon" in
      "☀️")
        bg_color="#0080FF" # Pure Sunny Blue
        text_color="#ffffff"
        ;;
      "🌤️"|"⛅")
        bg_color="#74c7ec" # Light Blue (Few clouds)
        text_color="#ffffff"
        ;;
      "☁️"|"󰖐")
        bg_color="#94e2d5" # High Cloud (Teal-ish Grey)
        text_color="#1e1e2e"
        ;;
      "🌥️"|"🌦️")
        bg_color="#bac2de" # Overcast Grey-Blue
        text_color="#1e1e2e"
        ;;
      "🌧️"|"🌨️"|"❄️"|"󰼶")
        bg_color="#6c7086" # Stormy/Rainy Dark Grey
        text_color="#ffffff"
        ;;
      "⛈️")
        bg_color="#313244" # Very Dark Storm Grey
        text_color="#ffffff"
        ;;
    esac
  fi
fi

# Return the styled string:
# [ Icon (bold) Temp (nobold) ] >
printf "#[fg=%s,bg=%s,bold] %s #[fg=%s,bg=%s,nobold]%s #[fg=%s,bg=#000000]" "$text_color" "$bg_color" "$display_icon" "$text_color" "$bg_color" "$temp_clean" "$bg_color"
