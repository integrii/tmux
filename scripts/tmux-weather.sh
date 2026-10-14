#!/usr/bin/env bash
# Fetch configured weather and return a color-coded tmux status string.
# Includes Day/Night logic based on sunset and moon phase icons.
# Caches rendered output (60s) to avoid re-parsing on every 1s status refresh.
# Checks NWS active alerts (5 min cache) and prepends 󰀦 when present.

WEATHER_LOCATION="${WEATHER_LOCATION:-$(tmux show-option -gqv @weather_location 2>/dev/null)}"
WEATHER_LOCATION="${WEATHER_LOCATION:-YOUR_LOCATION}"
LOCATION_KEY=$(printf '%s' "$WEATHER_LOCATION" | tr -c '[:alnum:]' '_')
NWS_ALERT_POINT="${NWS_ALERT_POINT:-$(tmux show-option -gqv @weather_alert_point 2>/dev/null)}"
ALERT_KEY=$(printf '%s' "${NWS_ALERT_POINT:-none}" | tr -c '[:alnum:]' '_')
CACHE_FILE="${CACHE_FILE:-/tmp/tmux_weather_cache_${LOCATION_KEY}}"
RENDER_CACHE="${RENDER_CACHE:-/tmp/tmux_weather_render_${LOCATION_KEY}}"
ALERT_CACHE="${ALERT_CACHE:-/tmp/tmux_weather_alerts_${ALERT_KEY}}"
CACHE_TTL=1200  # 20 minutes — raw weather fetch
RENDER_TTL=60   # 60 seconds — rendered output (handles day/night transitions)
ALERT_TTL=300   # 5 minutes — NWS alert check

now_ts=$(date +%s)

# Return cached render if fresh enough
render_age=$(stat -f %m "$RENDER_CACHE" 2>/dev/null || echo 0)
if (( now_ts - render_age < RENDER_TTL )) && [[ -s "$RENDER_CACHE" ]]; then
  cat "$RENDER_CACHE"
  exit 0
fi


arrow=$(printf '\xee\x82\xb0')
show_error() {
  rm -f "$CACHE_FILE" "$RENDER_CACHE"
  tmux set -g @weather_bg "#89b4fa"
  tmux set -g @weather_sep_active "#[fg=#89b4fa,bg=#0060CC]${arrow}"
  tmux set -g @weather_sep_inactive "#[fg=#89b4fa,bg=#404040]${arrow}"
  printf "#[fg=#1e1e2e,bg=#89b4fa,bold] 󰅚 "
  exit 0
}

# Check if we should force a fetch because of sunrise/sunset
last_fetch=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
force_fetch=0
if [[ -s "$CACHE_FILE" ]]; then
  cached_data=$(cat "$CACHE_FILE" 2>/dev/null)
  if [[ "$cached_data" == *"|"* ]]; then
    IFS='|' read -r _cached_icon _cached_condition _cached_temp _cached_wind cached_sunrise cached_sunset _cached_moon <<< "$cached_data"
  else
    cached_times=$(echo "$cached_data" | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}[0-9]{2}:[0-9]{2}:[0-9]{2}')
    cached_sunrise=${cached_times:0:8}
    cached_sunset=${cached_times:8:8}
  fi
  if [[ -n "${cached_sunrise:-}" && -n "${cached_sunset:-}" ]]; then
    today=$(date +%Y-%m-%d)
    c_sr_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $cached_sunrise" +%s 2>/dev/null)
    c_ss_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $cached_sunset" +%s 2>/dev/null)
    # If last fetch was before sunrise/sunset, and now is 1 min after that event, force fetch
    if [[ -n "$c_sr_ts" ]] && (( last_fetch < c_sr_ts && now_ts >= c_sr_ts + 60 )); then force_fetch=1; fi
    if [[ -n "$c_ss_ts" ]] && (( last_fetch < c_ss_ts && now_ts >= c_ss_ts + 60 )); then force_fetch=1; fi
  fi
fi

# Fetch new weather data if stale or forced by sun event
if (( now_ts - last_fetch > CACHE_TTL )) || (( force_fetch == 1 )); then
  response=$(curl -s --max-time 3 -w "\n%{http_code}" "wttr.in/${WEATHER_LOCATION// /+}?u&format=%c|%C|%t|%w|%S|%s|%m")
  http_code=$(echo "$response" | tail -1)
  weather=$(echo "$response" | sed '$d' | tr -d '+')
  if [[ "$http_code" == "200" && -n "$weather" && ! "$weather" =~ "html" ]]; then
    echo "$weather" > "$CACHE_FILE"
  else
    # Don't show error on force_fetch if cache still exists (just reuse it)
    if [[ ! -s "$CACHE_FILE" ]]; then show_error; fi
  fi
fi

data=$(cat "$CACHE_FILE" 2>/dev/null)
if [[ -z "$data" ]]; then
  show_error
fi

# NWS alerts are optional and use a point configured in local.conf.
alert_age=$(stat -f %m "$ALERT_CACHE" 2>/dev/null || echo 0)
if (( now_ts - alert_age > ALERT_TTL )); then
  if [[ -n "$NWS_ALERT_POINT" ]]; then
    alert_resp=$(curl -s --max-time 3 -w "\n%{http_code}" \
      -H "Accept: application/geo+json" \
      -H "User-Agent: tmux-weather-script" \
      "https://api.weather.gov/alerts/active?point=${NWS_ALERT_POINT}")
    alert_code=$(echo "$alert_resp" | tail -1)
    alert_body=$(echo "$alert_resp" | sed '$d')
    if [[ "$alert_code" == "200" ]]; then
      alert_count=$(echo "$alert_body" | grep -o '"event"' | wc -l | tr -d ' ')
      echo "$alert_count" > "$ALERT_CACHE"
    else
      echo "0" > "$ALERT_CACHE"
    fi
  else
    echo "0" > "$ALERT_CACHE"
  fi
fi

has_alerts=$(cat "$ALERT_CACHE" 2>/dev/null || echo 0)

# Parse raw data
if [[ "$data" == *"|"* ]]; then
  IFS='|' read -r icon condition_text temp wind sunrise_str sunset_str moon <<< "$data"
  temp="${temp#+}"
  # wttr.in pads %c to a fixed width; strip the padding so icon matches work
  icon="${icon#"${icon%%[![:space:]]*}"}"
  icon="${icon%"${icon##*[![:space:]]}"}"
else
  icon=$(echo "$data" | grep -oE '^[^0-9-]+' | sed 's/ *$//')
  temp=$(echo "$data" | grep -oE '[-+0-9]+°[CF]' | tr -d '+')
  times=$(echo "$data" | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}[0-9]{2}:[0-9]{2}:[0-9]{2}')
  moon=$(echo "$data" | grep -oE '.$')
  sunrise_str=${times:0:8}
  sunset_str=${times:8:8}
fi

today=$(date +%Y-%m-%d)
sunrise_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $sunrise_str" +%s 2>/dev/null)
sunset_ts=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $sunset_str" +%s 2>/dev/null)

temp_clean="${temp%[CF]}"

# If we couldn't parse a valid temperature, the cached data is garbage
if [[ -z "$temp_clean" ]]; then
  show_error
fi

temp_val="${temp_clean%°*}"
unit="${temp%*[0-9]}"
unit="${unit##*°}"

if [[ "$unit" == "C" ]]; then
  # Manual conversion: F = (C * 9/5) + 32
  # Using integer math for bash
  temp_f=$(( (temp_val * 9 / 5) + 32 ))
  temp_clean="${temp_f}°F"
else
  temp_clean="${temp_val}°${unit}"
fi

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
      "🌫️"|"🌫")
        bg_color="#e6e9ef"; text_color="#1e1e2e";;
    esac
    # Fog, mist, and haze read as white air, not blue sky
    case "$condition_text" in
      *[Ff]og*|*[Mm]ist*|*[Hh]aze*)
        bg_color="#e6e9ef"; text_color="#1e1e2e";;
    esac
  fi
fi

tmux set -g @weather_bg "$bg_color"
tmux set -g @weather_sep_active "#[fg=$bg_color,bg=#0060CC]${arrow}"
tmux set -g @weather_sep_inactive "#[fg=$bg_color,bg=#404040]${arrow}"

# Prepend warning triangle (amber) if active NWS alerts exist.
# The user ranges make the segments clickable; MouseDown1Status in tmux.conf opens their URLs.
if (( has_alerts > 0 )); then
  output=$(printf "#[range=user|weather-alert]#[fg=#fab387,bg=%s,bold] 󰀦#[norange]#[range=user|weather] #[fg=%s]%s #[fg=%s,nobold]%s #[norange]" \
    "$bg_color" "$text_color" "$display_icon" "$text_color" "$temp_clean")
else
  output=$(printf "#[range=user|weather]#[fg=%s,bg=%s,bold] %s #[fg=%s,bg=%s,nobold]%s #[norange]" \
    "$text_color" "$bg_color" "$display_icon" "$text_color" "$bg_color" "$temp_clean")
fi

# Cache rendered output
echo -n "$output" > "$RENDER_CACHE"
echo -n "$output"
