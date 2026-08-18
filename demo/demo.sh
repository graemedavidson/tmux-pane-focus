#!/usr/bin/env bash
#
# Drives a scripted tmux session showing tmux-pane-focus resizing panes as
# focus changes. Runs unattended: a background timeline manipulates the
# session directly via tmux commands (split-window/select-pane/send-keys -l)
# while this process stays attached in the foreground -- that attach is the
# only thing an asciinema/docker recording actually captures. The timeline
# ends by killing the session, which exits the attach and lets the
# container stop on its own.
#
# Deliberately avoids emulating keypresses (e.g. sending "C-a |" through
# send-keys) to drive tmux's own bindings: prefix-key state lives on the
# client, not the pane, so keys injected into a session with no (or a
# racing) attached client land as raw input in the shell instead of being
# resolved as bindings. Native tmux commands don't have that problem and
# still fire the plugin's hooks, since those trigger on the underlying
# event, not on how it was invoked.
#
# The settings menu (bound to shift-T) is shown the same way: `run-shell`
# invokes it directly rather than emulating "C-a T". It's shown as the final
# beat and left open into the session kill, since dismissing it would need a
# keypress reaching the client's menu overlay -- the same routing problem
# send-keys has with prefix bindings.
set -euo pipefail

readonly SESSION="demo"
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PLUGIN_DIR

tmux new-session -d -s "${SESSION}" -x 120 -y 30
sleep 1 # let focus.tmux register its hooks before anything else fires

# step DELAY CMD...
# Sleeps DELAY seconds (time for the viewer to see the current state), then
# runs CMD.
step() {
  local delay=$1
  shift
  sleep "${delay}"
  "$@"
}

# type_cmd TEXT
# Types TEXT into the active pane's shell and presses Enter, so the command
# (and its effect) is visible in the recording.
type_cmd() {
  tmux send-keys -t "${SESSION}" -l "$1"
  tmux send-keys -t "${SESSION}" Enter
}

(
  step 2 type_cmd 'tmux set-option -w "@pane-focus-size" "70"'

  step 2 tmux split-window -t "${SESSION}" -h -c "#{pane_current_path}"  # two panes; new (right) pane is active -> grows to 70%
  step 2 tmux select-pane -t "${SESSION}" -L                             # focus left -> it grows, right shrinks
  step 2 tmux select-pane -t "${SESSION}" -R                             # focus back right

  step 2 tmux split-window -t "${SESSION}" -v -c "#{pane_current_path}"  # split the focused pane -> nested 3-pane layout
  step 2 tmux select-pane -t "${SESSION}" -L                             # focus the wide left pane
  step 2 tmux select-pane -t "${SESSION}" -R                             # focus the wide left pane

  step 2 type_cmd 'tmux set-option -w "@pane-focus-direction" "|"'       # switch to width-only resizing
  step 2 tmux select-pane -t "${SESSION}" -D
  step 2 tmux select-pane -t "${SESSION}" -U
  step 2 tmux select-pane -t "${SESSION}" -L                             # height no longer changes, only width

  step 2 type_cmd 'tmux set-option -w "@pane-focus-size" "85"'           # crank the size up
  step 2 tmux select-pane -t "${SESSION}" -R
  step 2 tmux select-pane -t "${SESSION}" -L

  # shift-T's settings menu. Must run via -b (backgrounded): menu.sh itself
  # calls back into `tmux` (get_tmux_option/set_tmux_option), and a
  # non-backgrounded run-shell blocks the server on this command until it
  # completes -- deadlocking against menu.sh's own nested tmux calls.
  step 2 tmux run-shell -b "bash '${PLUGIN_DIR}/scripts/menu.sh'"

  # detach-client hangs while the menu overlay owns the client, so end the
  # recording with kill-session instead -- it tears the client down even
  # with the overlay open, and there's nothing left to clean up afterwards.
  step 3 tmux kill-session -t "${SESSION}"
) &

exec tmux attach -t "${SESSION}"
