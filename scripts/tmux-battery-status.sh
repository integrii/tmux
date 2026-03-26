#!/bin/bash

set -u

if ! command -v pmset >/dev/null 2>&1; then
        exit 0
fi

output="$(pmset -g batt 2>/dev/null || true)"

if ! grep -q "InternalBattery" <<<"$output"; then
        exit 0
fi

percentage="$(grep -Eo '[0-9]+%' <<<"$output" | head -n 1 | tr -d '%')"

if [[ -z "${percentage:-}" ]]; then
        exit 0
fi

status="$(tr '[:upper:]' '[:lower:]' <<<"$output")"
icon="󰁹"
color="#e7ff7a" # default battery color

if [[ "$status" == *charged* ]]; then
        icon="󰁹"
elif [[ "$status" == *discharging* ]]; then
        if (( percentage >= 95 )); then
                icon="󰁹"
        elif (( percentage >= 80 )); then
                icon="󰂁"
        elif (( percentage >= 60 )); then
                icon="󰁿"
        elif (( percentage >= 50 )); then
                icon="󰁾"
        elif (( percentage >= 35 )); then
                icon="󰁽"
        elif (( percentage >= 20 )); then
                icon="󰁼"
                color="#fab387" # orange
        elif (( percentage >= 10 )); then
                icon="󰁻"
                color="#f38ba8" # red
        else
                icon="󰁺"
                color="#f38ba8" # red
        fi
elif [[ "$status" == *charging* ]]; then
        icon="󰂄"
fi

# SQUARE THEME: No extra space between icon and percentage
printf '#[fg=%s,bg=default] %s#[fg=#C0C0C0,bg=default] %s%% ' "$color" "$icon" "$percentage"
