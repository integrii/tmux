# Eric's Tmux Configuration

A high-density, visually rich `tmux` configuration with Powerline-style window tabs, custom status modules, and automatic window renaming based on the running process (AI tools, SSH, btop, etc.).

## Features
- **Powerline-style Tabs:** Smooth arrow transitions between window tabs.
- **Process Icons:** Automatic icons for processes like `btop` (󰍛), `claude`, `ssh` (󰒍), `k9s` (󰠳), and more.
- **Dynamic Status Bar:** Modules (CPU, Battery, Weather, Podman, Kubernetes) that resize based on your terminal width.
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
