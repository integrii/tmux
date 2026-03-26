#!/bin/bash
# Powerline window tabs - context-aware arrows
#
# Each tab's leading/trailing arrows adapt based on whether adjacent
# windows are active, inactive, first, or last.
#
# Requires @active_idx to be set via hook (see tmux.conf):
#   set-hook -g after-select-window 'set -gF @active_idx "#{window_index}"'

tmux set -g window-status-format "#{?#{==:#{window_index},1},,#{?#{==:#{e|-:#{window_index},1},#{@active_idx}},,}}#[fg=#999999,bg=#404040,bold] #{?#{==:#I,1},1,#{?#{==:#I,2},2,#{?#{==:#I,3},3,#{?#{==:#I,4},4,#{?#{==:#I,5},5,#{?#{==:#I,6},6,#{?#{==:#I,7},7,#{?#{==:#I,8},8,#{?#{==:#I,9},9,#{?#{==:#I,10},10,#I}}}}}}}}}} #[nobold,fg=#404040,bg=#3a3a3a] #{@pane_icon}#[fg=#777777,bg=#3a3a3a]#W #{?#{==:#{window_index},#{session_windows}},#[fg=#3a3a3a#,bg=default],#{?#{==:#{e|+:#{window_index},1},#{@active_idx}},#[fg=#3a3a3a#,bg=#0060CC],#[fg=#3a3a3a#,bg=#404040]}}"

tmux set -g window-status-current-format "#{?#{==:#{window_index},1},,}#[fg=#FFFFFF,bg=#0060CC,bold] #{?#{==:#I,1},1,#{?#{==:#I,2},2,#{?#{==:#I,3},3,#{?#{==:#I,4},4,#{?#{==:#I,5},5,#{?#{==:#I,6},6,#{?#{==:#I,7},7,#{?#{==:#I,8},8,#{?#{==:#I,9},9,#{?#{==:#I,10},10,#I}}}}}}}}}} #[nobold,fg=#0060CC,bg=#0080FF] #{@pane_icon}#[fg=#FFFFFF,bg=#0080FF]#W #{?#{==:#{window_index},#{session_windows}},#[fg=#0080FF#,bg=default],#[fg=#0080FF,bg=#404040]}"

# Separator must be empty for flush tabs
tmux set -g window-status-separator ""

tmux set -g status-left "#(${HOME}/.sh/tmux-weather.sh)#{?#{==:1,#{@active_idx}},#{E:@weather_sep_active},#{E:@weather_sep_inactive}}"
