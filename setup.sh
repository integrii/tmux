#!/bin/bash
# setup.sh - Install Eric's tmux configuration

set -e

# Base directories
TMUX_CONFIG_DIR="$HOME/.config/tmux"
SH_DIR="$HOME/.sh"

# Prompt for location (stored in overlay, not in repo)
read -p "Enter your location (Zip Code or City) for weather updates [skip]: " LOCATION

echo "Creating directories..."
mkdir -p "$TMUX_CONFIG_DIR/theme"
mkdir -p "$SH_DIR"

# Get the directory of this script
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean up stale symlinks (from previous installs / restructures)
cleanup_stale_symlinks() {
    local dir="$1"
    find "$dir" -type l ! -exec test -e {} \; -print 2>/dev/null | while read -r link; do
        local target=$(readlink "$link")
        read -p "  Stale symlink: $link -> $target (remove?) [y/N] " answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            rm "$link"
            echo "  Removed."
        else
            echo "  Kept."
        fi
    done
}

echo "Checking for stale symlinks..."
cleanup_stale_symlinks "$TMUX_CONFIG_DIR"
cleanup_stale_symlinks "$SH_DIR"

# Write weather location to overlay settings if provided
if [[ -n "$LOCATION" ]]; then
  mkdir -p "$TMUX_CONFIG_DIR/overlay"
  OVERLAY_SETTINGS="$TMUX_CONFIG_DIR/overlay/settings.conf"
  if [[ -f "$OVERLAY_SETTINGS" ]] && grep -q '@weather_location' "$OVERLAY_SETTINGS"; then
    sed -i '' "s|^set -g @weather_location .*|set -g @weather_location \"$LOCATION\"|" "$OVERLAY_SETTINGS"
  else
    echo "" >> "$OVERLAY_SETTINGS"
    echo "# Weather widget location (zip code or city)" >> "$OVERLAY_SETTINGS"
    echo "set -g @weather_location \"$LOCATION\"" >> "$OVERLAY_SETTINGS"
  fi
  echo "Weather location set to: $LOCATION"
fi

echo "Installing configuration files..."
ln -sf "$REPO_DIR/config/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
ln -sf "$REPO_DIR/config/theme/integrii.conf" "$TMUX_CONFIG_DIR/theme/integrii.conf"
ln -sf "$REPO_DIR/config/theme/modules.conf" "$TMUX_CONFIG_DIR/theme/modules.conf"
ln -sf "$REPO_DIR/config/theme/kubernetes.conf" "$TMUX_CONFIG_DIR/theme/kubernetes.conf"
ln -sf "$REPO_DIR/config/theme/podman.conf" "$TMUX_CONFIG_DIR/theme/podman.conf"
ln -sf "$REPO_DIR/config/theme/directory.conf" "$TMUX_CONFIG_DIR/theme/directory.conf"

echo "Installing scripts..."
for script in "$REPO_DIR"/scripts/*.sh; do
    ln -sf "$script" "$SH_DIR/$(basename "$script")"
done

# Check for TPM
if [ ! -d "/opt/homebrew/opt/tpm" ] && [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    echo "Warning: TPM (Tmux Plugin Manager) not found."
    echo "Please install it via Homebrew: brew install tpm"
    echo "Or manually: git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm"
fi

echo "Setup complete! Reload tmux with 'tmux source $TMUX_CONFIG_DIR/tmux.conf' if already running."
echo "Press Prefix + I in tmux to install plugins."