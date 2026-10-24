# Changelog

## v1.1.1

- Run weather and right-side status commands on the one-second background scan, not on every animation redraw.
- Publish cached status and agent indicators through hidden tmux environment values to avoid unnecessary pane and popup redraws.
- Start the status publisher with the theme, even before an agent hook runs.
- Smooth agent animations with a fixed 25 fps clock and optional Homebrew Bash sleep builtin.
- Resolve cached indicators in window tabs and the window picker; recognize the OpenCode terminal shim in picker labels.
- Add an isolated regression test for status scan frequency and shell-job-free status formats.
- Document the Bash 5 requirement. Keep weather locations and machine-specific settings in local configuration.
