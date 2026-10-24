# integrii's tmux configuration

<p style="text-align:center;">
  <img width="1470" height="26" alt="image" src="https://github.com/user-attachments/assets/7db41a3a-a1b2-4ac6-aa59-02f7c66dc20d" />

</p>

A personal tmux setup with a transparent dark theme, Powerline window tabs, responsive status modules, process-aware names, and optional animated agent indicators. The repository contains the general configuration. Machine-specific values belong in `~/.config/tmux/local.conf`.

## Features

- `Ctrl-Space` prefix, with `Ctrl-Space` twice to return to the last window.
- Vim-style pane navigation with `Ctrl-h/j/k/l`, plus `h` and `l` for adjacent windows.
- Powerline-style tabs with process icons, animated agent status, and a searchable window picker.
- Clickable weather, Kubernetes, Podman, battery, and directory status segments.
- Context-sensitive status widths, cached status scripts, NWS alerts, and Podman connection selection.
- Pane titles are disabled. Shared windows keep stable dimensions when attached clients have different sizes.
- TPM plugin declarations for sensible defaults, clipboard, Vim navigation, weather, mouse behavior, and history search.

## Requirements

- tmux 3.3 or newer.
- Bash 5 or newer on `PATH` for the status animator (`EPOCHREALTIME` timing).
- Nerd Font for the status icons.
- TPM for plugin installation.
- `fzf` for the window picker and Podman selector.
- Optional: `kubectx` and `kubens`; Podman; `jq` and `curl` for weather alerts.

## Install

```bash
git clone https://github.com/integrii/tmux.git ~/git/tmux
cd ~/git/tmux
./setup.sh
```

Setup links the tracked config and scripts into `~/.config/tmux` and `~/.sh`. It asks for a weather location and writes it to the untracked `~/.config/tmux/local.conf`. The public repo does not contain a personal location. Existing local settings are kept.

Install the declared TPM plugins by pressing `Prefix + I` in tmux. The plugin manager can live at `~/.config/tmux/plugins/tpm/tpm` or the Homebrew path `/opt/homebrew/opt/tpm/share/tpm/tpm`.

To enable NWS alerts, add a point for your area to `~/.config/tmux/local.conf`:

```tmux
set -g @weather_alert_point "latitude,longitude"
```

## Key bindings

| Action | Keys |
| --- | --- |
| Prefix | `Ctrl-Space` |
| Last window | `Ctrl-Space`, then `Ctrl-Space` |
| Previous/next window | `h` / `l` |
| Navigate panes | `Ctrl-h`, `Ctrl-j`, `Ctrl-k`, `Ctrl-l` |
| Vertical/horizontal split | `Prefix + \|` / `Prefix + -` |
| New window | `Prefix + c` |
| Window picker | `Prefix + w` |
| Reload config | `Prefix + r` |
| Search backward/forward | `F12` / `Shift-F12` |
| Search prompt | `Prefix + u` |
| Cycle layouts | `Prefix + Space` |

Mouse support is enabled. Drag a status tab to move its window. Click status segments to open their related picker or popup.

## Optional agent state hooks

`scripts/tmux-agent-state.sh` records `working`, `question`, `idle`, or `error` state for the tmux pane that owns a Codex or Claude hook. `scripts/tmux-agent-stop-state.sh` resets the state after a normal stop. The status renderer also detects agent processes when no hook state is available. This repo does not install or modify agent hook configuration.

## Status modules

The left side shows local weather and the active-window separator. The right side adapts to terminal width and can show the current directory, Kubernetes context and namespace, Podman connection, and battery level. Status values use short-lived cache files under `/tmp`.

The animator starts with the theme and runs slow weather and right-side status commands once per one-second scan, separately from the 25 fps animation redraws. It publishes cached values in hidden tmux environment variables (`TMUX_AGENT_STATUS_LEFT` and `TMUX_AGENT_STATUS_RIGHT`); status formats read those values without starting shell jobs on each redraw.

Run the isolated regression test with `python3 tests/test_animator.py` (requires Bash 5 on `PATH`). It uses mock commands, without touching a real tmux server or the network.

The palette uses blue active tabs, grey inactive tabs, and warm accents for weather and Podman. Theme files live in `config/theme/`.
