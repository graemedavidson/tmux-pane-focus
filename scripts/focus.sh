#!/usr/bin/env bash

PANE_COUNT=$(tmux list-panes | wc -l)
if [[ $PANE_COUNT -eq 1 ]]; then
  # Nothing to do
  exit 0
fi

horizontal_count=0
last_horizontal_val=0
vertical_count=0
last_vertical_val=0

RIGHT_PANES=$(tmux list-panes -F "#{pane_right}" | sort -n)
echo "$RIGHT_PANES"
for PT in ${RIGHT_PANES}; do
  IFS=- read -r PAN_RIGHT < <(echo "${PT}")
  if [[ $PAN_RIGHT -gt last_horizontal_val ]]; then
    ((horizontal_count=horizontal_count+1))
    last_horizontal_val=$PAN_RIGHT
  fi
done

BOTTOM_PANES=$(tmux list-panes -F "#{pane_bottom}" | sort -n)
echo "$BOTTOM_PANES"
for PT in ${BOTTOM_PANES}; do
  IFS=- read -r PAN_BOTTOM < <(echo "${PT}")
  if [[ $PAN_BOTTOM -gt last_vertical_val ]]; then
    ((vertical_count=vertical_count+1))
    last_vertical_val=$PAN_BOTTOM
  fi
done

echo "horizontal_count: ${horizontal_count}"
echo "vertical_count: ${vertical_count}"

# Determine ratio for size of inactive panels

## Example 1: active panel (50%/50%), remaining share (50%/50% / number of panels)
### ? on a vertical or horizontal plane does it matter if inactive is given less than what would equal 100%, does it just take up reamining space?

PANELS=$(tmux list-panes -F "#{pane_active}-#{pane_id}" | sort -nr)
for PANEL in ${PANELS}; do
  IFS=- read -r ACTIVE ID < <(echo "${PANEL}")
  # echo "$ACTIVE"
  if [[ $ACTIVE -eq 1 ]]; then
    tmux resize-pane -t "${ID}" -x 50% -y 50%
  else
    PW=50
    PH=50
    if [[ $horizontal_count -gt 1 ]]; then
      PW=$((50/((horizontal_count-1))))
    fi
    if [[ $vertical_count -gt 1 ]]; then
      PH=$((50/((vertical_count-1))))
    fi
    echo "PW: $PW, PH: $PH"
    tmux resize-pane -t "${ID}" -x ${PW}% -y ${PH}%
  fi
done

#######################################################################################
# ToDo:
# - Consider what happens when multiple panes exist and the lines between affect calculations for shared inactive panel percentage
# - Consider different options for focus:
#   1. Vertical and Horizontal change so active panel takes most of screen.
#   2. Horizontal change only, leaving Vertical size unchanged
#   3. Vertical change only, leaving Horizontal size unchanged
#   4. Ratio differences, so 50%, 80%, so how much of the screen is left for other panes
#   5. Allow off which returns to default behaviour

#######################################################################################
# Test Code:

# DEFAULT_ACTIVE_PANE_HEIGHT=70
# DEFAULT_ACTIVE_PANE_WIDTH=70
# tmux set-env -g FOCUS_ACTIVE_PANE_HEIGHT ${DEFAULT_ACTIVE_PANE_HEIGHT}
# tmux set-env -g FOCUS_ACTIVE_PANE_WIDTH ${DEFAULT_ACTIVE_PANE_WIDTH}

# DEFAULT_INACTIVE_PANE_HEIGHT=30
# DEFAULT_INACTIVE_PANE_WIDTH=30
# tmux set-env -g FOCUS_INACTIVE_PANE_HEIGHT ${DEFAULT_INACTIVE_PANE_HEIGHT}
# tmux set-env -g FOCUS_INACTIVE_PANE_WIDTH ${DEFAULT_INACTIVE_PANE_WIDTH}

# tmux set -w window-active-style "bg=blue"

# PANEL_SPLIT_SIZE=1    # The size on screen of a split.

# Reset the entire layout to allow for oddly configured windows when manually manipulated?
# tmux select-layout -E

# Resize all other panes to allow for a consistent visibility
# NON_ACTIVE_PANELS=$(tmux list-panes -F "#{pane_id}-#{pane_height}-#{pane_width}-#{pane_active}")
# for PANEL in ${NON_ACTIVE_PANELS}; do
#   IFS=- read -r PAN_ID PAN_H PAN_W PAN_ACTIVE < <(echo "${PANEL}")
#   if [[ $PAN_ACTIVE -eq 1 ]]; then
#     tmux resize-pane -t "${PAN_ID}" -x ${DEFAULT_ACTIVE_PANE_WIDTH}% -y ${DEFAULT_ACTIVE_PANE_HEIGHT}%
#   else
#     tmux resize-pane -t "${PAN_ID}" -x ${DEFAULT_INACTIVE_PANE_WIDTH}% -y ${DEFAULT_INACTIVE_PANE_HEIGHT}%
#   fi
# done

# tmux set -w window-active-style "bg=blue"
# sleep 2
# tmux set -w window-active-style "bg=black"

# resize-pane [-DLMRTUZ] [-t target-pane] [-x width] [-y height] [adjustment]
# tmux resize-pane -x "${DEFAULT_ACTIVE_PANE_WIDTH}%" -y "${DEFAULT_ACTIVE_PANE_HEIGHT}%"

# Potentially useful if we want to get current sizes for a more customised design.
# IFS=- read -r WIN_H WIN_W < <(tmux list-windows -F "#{window_height}-#{window_width}")
# echo "${WIN_H}x${WIN_W}"

# IFS=- read -r PAN_H PAN_W PAN_ACTIVE < <(tmux list-panes -F "#{pane_height}-#{pane_width}-#{pane_active}" | grep "1$")
# echo "${PAN_H}x${PAN_W} = ${PAN_ACTIVE}"
