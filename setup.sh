#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONFIG_DIR="$HOME/.config/tmux"
SH_DIR="$HOME/.sh"
LOCAL_CONF="$TMUX_CONFIG_DIR/local.conf"

mkdir -p "$TMUX_CONFIG_DIR/theme" "$TMUX_CONFIG_DIR/scripts" "$SH_DIR"
ln -sfn "$REPO_DIR/config/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
for file in "$REPO_DIR"/config/theme/*.conf; do
  ln -sfn "$file" "$TMUX_CONFIG_DIR/theme/$(basename "$file")"
done
ln -sfn "$REPO_DIR/config/scripts/list-markers.sh" "$TMUX_CONFIG_DIR/scripts/list-markers.sh"
for file in "$REPO_DIR"/scripts/*; do
  [[ -f "$file" ]] || continue
  ln -sfn "$file" "$SH_DIR/$(basename "$file")"
done

if [[ ! -e "$LOCAL_CONF" ]]; then
  read -r -p 'Weather location (ZIP or city) [YOUR_LOCATION]: ' location
  location=${location:-YOUR_LOCATION}
  if [[ ! "$location" =~ ^[[:alnum:]][[:alnum:][:space:],._-]*$ ]]; then
    echo 'Use letters, numbers, spaces, commas, periods, underscores, or hyphens in the location.' >&2
    exit 1
  fi
  printf 'set -g @weather_location "%s"\n' "$location" > "$LOCAL_CONF"
  echo "Wrote local weather settings to $LOCAL_CONF"
else
  echo "Keeping existing local settings in $LOCAL_CONF"
fi

if [[ ! -x "$HOME/.config/tmux/plugins/tpm/tpm" && ! -x /opt/homebrew/opt/tpm/share/tpm/tpm ]]; then
  echo 'Install TPM to ~/.config/tmux/plugins/tpm or install it with Homebrew.'
fi

echo "Linked tmux config and scripts from $REPO_DIR. Reload with: tmux source-file ~/.config/tmux/tmux.conf"
echo 'Install configured plugins with Prefix + I.'
