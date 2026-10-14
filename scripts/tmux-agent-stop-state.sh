#!/usr/bin/env bash
# Reset the indicator after a normal Stop event. Claude's StopFailure event
# sets the error state separately, without inferring failures from final prose.

"$HOME/.sh/tmux-agent-state.sh" idle || exit $?
printf '{}\n'
