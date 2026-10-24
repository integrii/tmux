#!/bin/bash
# Powerline window tabs - context-aware arrows
#
# Each tab's leading/trailing arrows adapt based on whether adjacent
# windows are active, inactive, first, or last.
#
# Uses tmux's built-in active_window_index format, computed live per redraw
# (no hook-maintained variable, so no race with window open/close events).

tmux set -g window-status-format "#{?#{==:#{window_index},1},,#{?#{==:#{e|-:#{window_index},1},#{active_window_index}},,}}#[fg=#999999,bg=#404040,bold] #{?#{==:#I,0},󰬹,#{?#{==:#I,1},󰬺,#{?#{==:#I,2},󰬻,#{?#{==:#I,3},󰬼,#{?#{==:#I,4},󰬽,#{?#{==:#I,5},󰬾,#{?#{==:#I,6},󰬿,#{?#{==:#I,7},󰭀,#{?#{==:#I,8},󰭁,#{?#{==:#I,9},󰭂,#I}}}}}}}}}} #[nobold,fg=#404040,bg=#3a3a3a] #{?#{E:@pane_icons},#{E:@pane_icons} ,}#[fg=#777777,bg=#3a3a3a]#W#{?window_zoomed_flag, 🔍,} #{?#{==:#{window_index},#{session_windows}},#[fg=#3a3a3a#,bg=default],#{?#{==:#{e|+:#{window_index},1},#{active_window_index}},#[fg=#3a3a3a#,bg=#0060CC],#[fg=#3a3a3a#,bg=#404040]}}"

tmux set -g window-status-current-format "#{?#{==:#{window_index},1},,}#[fg=#FFFFFF,bg=#0060CC,bold] #{?#{==:#I,0},󰬹,#{?#{==:#I,1},󰬺,#{?#{==:#I,2},󰬻,#{?#{==:#I,3},󰬼,#{?#{==:#I,4},󰬽,#{?#{==:#I,5},󰬾,#{?#{==:#I,6},󰬿,#{?#{==:#I,7},󰭀,#{?#{==:#I,8},󰭁,#{?#{==:#I,9},󰭂,#I}}}}}}}}}} #[nobold,fg=#0060CC,bg=#0080FF] #{?#{E:@pane_icons},#{E:@pane_icons} ,}#[fg=#FFFFFF,bg=#0080FF]#W#{?window_zoomed_flag, 🔍,} #{?#{==:#{window_index},#{session_windows}},#[fg=#0080FF#,bg=default],#[fg=#0080FF#,bg=#404040]}"

# Separator must be empty for flush tabs
tmux set -g window-status-separator ""

tmux set -g status-left '#{TMUX_AGENT_STATUS_LEFT}#{?#{==:1,#{active_window_index}},#{E:@weather_sep_active},#{E:@weather_sep_inactive}}'
