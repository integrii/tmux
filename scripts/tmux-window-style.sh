#!/bin/bash
# Powerline window tabs - Flush end-to-end
#
# Since tmux reports window-status-separator is already '',
# the "gap" must be literal space characters at the END of our format strings.

# Function to map window index to Nerd Font square icons
# Corrected for base-index 1 and consistent symbols
get_icon_index() {
  # Map digits 0-9 to their square numeric box icons
  # 󰎤=0, 󰎧=1, 󰎪=2, 󰎭=3, 󰎰=4, 󰎳=5, 󰎶=6, 󰎹=7, 󰎼=8, 󰎿=9
  echo "#{?#{==:#I,0},󰎤,#{?#{==:#I,1},󰎧,#{?#{==:#I,2},󰎪,#{?#{==:#I,3},󰎭,#{?#{==:#I,4},󰎰,#{?#{==:#I,5},󰎳,#{?#{==:#I,6},󰎶,#{?#{==:#I,7},󰎹,#{?#{==:#I,8},󰎼,#{?#{==:#I,9},󰎿,#I}}}}}}}}}}"
}

ICON_I=$(get_icon_index)

# Inactive Window:
# Ends with the arrow character EXACTLY. No trailing spaces.
tmux set -g window-status-format "#[fg=#000000,bg=#404040]#[fg=#999999,bg=#404040] $ICON_I #[fg=#404040,bg=#3a3a3a] #{@pane_icon}#[fg=#777777,bg=#3a3a3a]#W #[fg=#3a3a3a,bg=#000000]"

# Active Window:
# Ends with the arrow character EXACTLY. No trailing spaces.
tmux set -g window-status-current-format "#[fg=#000000,bg=#0060CC]#[fg=#FFFFFF,bg=#0060CC] $ICON_I #[fg=#0060CC,bg=#0080FF] #{@pane_icon}#[fg=#FFFFFF,bg=#0080FF]#W #[fg=#0080FF,bg=#000000]"

# Double check the separator
tmux set -g window-status-separator ""

tmux set -g status-left "#(${HOME}/.sh/tmux-weather.sh)"
