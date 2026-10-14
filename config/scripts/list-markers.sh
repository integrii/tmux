#!/usr/bin/env bash
# replace the default < and > window list overflow markers in status-format[0] with ellipses
old='#[list=left-marker]<#[list=right-marker]>'
new="#[list=left-marker,fg=#FFFFFF,bg=#3a3a3a]…#[list=right-marker,fg=#FFFFFF,bg=#3a3a3a]…"
# read the stock format from a throwaway server so a reload never stacks on an edited value
fmt=$(tmux -L list-markers-tmp -f /dev/null start-server \; show -gv 'status-format[0]')
tmux -L list-markers-tmp kill-server 2>/dev/null
[ -n "$fmt" ] && tmux set -g 'status-format[0]' "${fmt/"$old"/$new}"
