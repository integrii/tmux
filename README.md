# integrii's Tmux Configuration

<p style="text-align:center;">
<img width="1470" height="26" alt="image" src="https://github.com/user-attachments/assets/affef63e-0801-493e-8a34-96443a7e4d3f" />
</p>

A high-density, visually rich `tmux` configuration with Powerline-style window tabs, custom status modules, and automatic window renaming based on the running process (AI tools, SSH, btop, etc.).

## Features
- **Powerline-style Tabs:** Smooth arrow transitions between window tabs.
- **Process Icons:** Automatic icons for processes like `btop` (󰍛), `claude`, `ssh` (󰒍), `k9s` (󰠳), and more.
- **Dynamic Status Bar:** Modules (CPU, Battery, Weather, Podman, Kubernetes) that dynamically hide or show based on your terminal width to prevent clutter.
- **Smart Weather:** A custom weather script with Day/Night logic that displays moon phases at night and dynamically changes the status bar color based on the actual weather (e.g., sunny blue, stormy grey, overcast teal).
- **Catppuccin Mocha Theme:** A beautiful dark theme with custom accent colors.
- **Vim Bindings:** Full Vim-style navigation and selection within tmux.

## Installation

### 1. Prerequisites
- **Nerd Fonts:** Ensure you are using a [Nerd Font](https://www.nerdfonts.com/) in your terminal for icons.
- **TPM (Tmux Plugin Manager):**
  ```bash
  # Via Homebrew (recommended for macOS)
  brew install tpm
  
  # Or manually
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ```

### 2. Clone and Setup
Clone this repository and run the setup script to symlink the configuration to your `$HOME` directory:

```bash
git clone https://github.com/your-username/tmux.git ~/git/tmux
cd ~/git/tmux
chmod +x setup.sh
./setup.sh
```

### 3. Install Plugins
Start a new tmux session and press `Prefix + I` (Capital I) to install the plugins.
*Note: The default Prefix is `Ctrl+s`.*

## Key Bindings
- **Prefix:** `Ctrl+s`
- **Vertical Split:** `Prefix + |`
- **Horizontal Split:** `Prefix + -`
- **Switch Panes:** `Ctrl + h/j/k/l` (no Prefix needed)
- **Last Window:** `Ctrl+s + Ctrl+s`
- **Reload Config:** `Prefix + r`
- **Search History:** `Prefix + /` (via tmux-copycat)

## Plugins & Scripts

This configuration relies on several custom scripts located in the `scripts/` directory to provide its rich functionality:

- **`kubectl.tmux.sh`**: Displays the current Kubernetes context and namespace (requires `kubectx` and `kubens`).
- **`podman.tmux.sh`**: Shows the active Podman machine name, or "local" if using the default machine.
- **`resize-tmux-modules.sh`**: Dynamically hides or shows status bar modules (Kubernetes, Podman, Battery, etc.) based on the current terminal width to prevent overlapping.
- **`tmux-battery-status.sh`**: Provides a color-coded battery percentage and state icon (charging/discharging) using MacOS `pmset`.
- **`tmux-pane-icon.sh`**: Automatically detects running processes in a pane (like `ssh`, `btop`, `k9s`, or AI tools like `claude` and `gemini`) and assigns a unique icon and color to the window name.
- **`tmux-weather.sh`**: Fetches weather data from `wttr.in` and provides a dynamic status module. It includes Day/Night logic (showing moon phases at night) and changes the background color based on weather conditions (e.g., blue for sunny, grey for rain).
- **`tmux-window-style.sh`**: Implements the custom Powerline-style window tabs, including the Nerd Font numeric icons for window indices and the overall status line styling.
