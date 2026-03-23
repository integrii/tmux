#!/bin/bash
# Powerline window tabs - Flush end-to-end
#
# Since tmux reports window-status-separator is already '',
# the "gap" must be literal space characters at the END of our format strings.

# Inactive Window:
# Ends with the arrow character EXACTLY. No trailing spaces.
tmux set -g window-status-format "#[fg=#000000,bg=#404040]#[fg=#999999,bg=#404040] #I #[fg=#404040,bg=#3a3a3a] #{@pane_icon}#[fg=#777777,bg=#3a3a3a]#W #[fg=#3a3a3a,bg=#000000]"

# Active Window:
# Ends with the arrow character EXACTLY. No trailing spaces.
tmux set -g window-status-current-format "#[fg=#000000,bg=#0060CC]#[fg=#FFFFFF,bg=#0060CC] #I #[fg=#0060CC,bg=#0080FF] #{@pane_icon}#[fg=#FFFFFF,bg=#0080FF]#W #[fg=#0080FF,bg=#000000]"

# Double check the separator
tmux set -g window-status-separator ""

tmux set -g status-left "#(${HOME}/.sh/tmux-weather.sh)"
