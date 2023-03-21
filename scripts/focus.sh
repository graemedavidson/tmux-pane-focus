#!/usr/bin/env bash

DEFAULT_ACTIVE_PANE_HEIGHT=50
DEFAULT_ACTIVE_PANE_WIDTH=50
tmux set-env -g FOCUS_ACTIVE_PANE_HEIGHT ${DEFAULT_ACTIVE_PANE_HEIGHT}
tmux set-env -g FOCUS_ACTIVE_PANE_WIDTH ${DEFAULT_ACTIVE_PANE_WIDTH}

DEFAULT_INACTIVE_PANE_HEIGHT=30
DEFAULT_INACTIVE_PANE_WIDTH=30
tmux set-env -g FOCUS_INACTIVE_PANE_HEIGHT ${DEFAULT_INACTIVE_PANE_HEIGHT}
tmux set-env -g FOCUS_INACTIVE_PANE_WIDTH ${DEFAULT_INACTIVE_PANE_WIDTH}

# tmux set -w window-active-style "bg=blue"

# PANEL_SPLIT_SIZE=1    # The size on screen of a split.

# Reset the entire layout to allow for oddly configured windows when manually manipulated?
# tmux select-layout -E


# Resize all other panes to allow for a consistent visibility
NON_ACTIVE_PANELS=$(tmux list-panes -F "#{pane_id}-#{pane_height}-#{pane_width}-#{pane_active}" | grep "0$")
for PANEL in ${NON_ACTIVE_PANELS}; do
  IFS=- read -r PAN_ID PAN_H PAN_W PAN_ACTIVE < <(echo "${PANEL}")
  # tmux set -w window-active-style "bg=blue"
  tmux resize-pane -t "${PAN_ID}" -x ${DEFAULT_INACTIVE_PANE_WIDTH}% -y ${DEFAULT_INACTIVE_PANE_HEIGHT}%
  # sleep 2
  # tmux set -w window-active-style "bg=black"
done

# resize-pane [-DLMRTUZ] [-t target-pane] [-x width] [-y height] [adjustment]
tmux resize-pane -x "${DEFAULT_ACTIVE_PANE_WIDTH}%" -y "${DEFAULT_ACTIVE_PANE_HEIGHT}%"

# Potentially useful if we want to get current sizes for a more customised design.
# IFS=- read -r WIN_H WIN_W < <(tmux list-windows -F "#{window_height}-#{window_width}")
# echo "${WIN_H}x${WIN_W}"

# IFS=- read -r PAN_H PAN_W PAN_ACTIVE < <(tmux list-panes -F "#{pane_height}-#{pane_width}-#{pane_active}" | grep "1$")
# echo "${PAN_H}x${PAN_W} = ${PAN_ACTIVE}"
