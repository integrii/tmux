#!/bin/bash
# setup.sh - Install Eric's tmux configuration

set -e

# Base directories
TMUX_CONFIG_DIR="$HOME/.config/tmux"
SH_DIR="$HOME/.sh"

# Prompt for location
read -p "Enter your location (Zip Code or City) for weather updates [98332]: " LOCATION
LOCATION=${LOCATION:-98332}

echo "Creating directories..."
mkdir -p "$TMUX_CONFIG_DIR/plugins/tmux/custom"
mkdir -p "$SH_DIR"

# Get the directory of this script
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Customizing configuration for location: $LOCATION..."
# Replace location in scripts and configs
sed -i '' "s/98332/$LOCATION/g" "$REPO_DIR/scripts/tmux-weather.sh"
sed -i '' "s/98332/$LOCATION/g" "$REPO_DIR/config/catppuccin.conf"

echo "Installing configuration files..."
ln -sf "$REPO_DIR/config/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
ln -sf "$REPO_DIR/config/catppuccin.conf" "$TMUX_CONFIG_DIR/catppuccin.conf"
ln -sf "$REPO_DIR/config/catppuccin.modules.conf" "$TMUX_CONFIG_DIR/catppuccin.modules.conf"
ln -sf "$REPO_DIR/config/custom/kubernetes.conf" "$TMUX_CONFIG_DIR/plugins/tmux/custom/kubernetes.conf"
ln -sf "$REPO_DIR/config/custom/podman.conf" "$TMUX_CONFIG_DIR/plugins/tmux/custom/podman.conf"

echo "Installing scripts..."
for script in "$REPO_DIR"/scripts/*.sh; do
    ln -sf "$script" "$SH_DIR/$(basename "$script")"
done

# Check for TPM
if [ ! -d "/opt/homebrew/opt/tpm" ] && [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Warning: TPM (Tmux Plugin Manager) not found."
    echo "Please install it via Homebrew: brew install tpm"
    echo "Or manually: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
fi

echo "Setup complete! Reload tmux with 'tmux source $TMUX_CONFIG_DIR/tmux.conf' if already running."
echo "Press Prefix + I in tmux to install plugins."
