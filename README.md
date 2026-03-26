# integrii's Tmux Configuration

<p style="text-align:center;">
<img width="1470" height="21" alt="image" src="https://github.com/user-attachments/assets/590c0554-3831-4311-ab00-b647a3f8a27d" />
</p>

A high-density, visually rich `tmux` configuration with Powerline-style window tabs, custom status modules, and automatic window renaming based on the running process (AI tools, SSH, btop, etc.). The weather stays in the top left to remind you to go outside.

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

## Status Bar Modules

The status bar is designed to be high-density but clean, automatically hiding modules based on your terminal width to prevent overlap.

### Right Side Plugins (Responsive Modules)
These modules appear in the top right and hide dynamically as your terminal window gets smaller:

- **Directory:** Shows the current working directory. Always visible.
- **Kubernetes:** Displays the active `kubectx` context and `kubens` namespace. (Requires `kubectx` and `kubens`)
- **Podman:** Shows the currently active Podman machine name, or "local" if the default machine is in use.
- **Battery:** A dynamic battery indicator that changes color (green, orange, red) based on percentage and includes a charging/discharging icon.

### Left Side Plugins
- **Weather:** A smart weather module that fetches data from `wttr.in`. It features:
  - **Dynamic Colors:** The status bar background color changes based on conditions (e.g., blue for sunny, teal for overcast, grey for rain).
  - **Day/Night Logic:** Automatically switches between a sun icon and the current moon phase based on local sunrise/sunset times.

### Window Tabs
- **Process-Aware Icons:** Window names automatically update based on the running process. For example, running `ssh` will show a 󰒍 icon and the hostname, while `btop` shows a 󰍛 icon. AI tools like `claude`, `gemini`, and `codex` also have unique icons and colors.
- **Numeric Icons:** Window indices (1, 2, 3...) are displayed using stylized Nerd Font numeric icons for a cleaner look.
