#!/usr/bin/env bash

IFS=- read -r WINDOW_HEIGHT WINDOW_WIDTH WINDOW_ACTIVE < <(tmux list-windows -F "#{window_height}-#{window_width}-#{window_active}" | grep "1$")

PANE_COUNT=$(tmux list-panes | wc -l)
# if [[ $PANE_COUNT -eq 1 ]]; then
#   # Nothing to do
#   exit 0
# fi

# PANEL_SPLIT_SIZE=1    # The size on screen of a split bar.
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

# PANELS=$(tmux list-panes -F "#{pane_active}-#{pane_id}" | sort -nr)
# for PANEL in ${PANELS}; do
#   IFS=- read -r ACTIVE ID < <(echo "${PANEL}")
#   if [[ $ACTIVE -eq 1 ]]; then
#     tmux resize-pane -t "${ID}" -x 50% -y 50%
#   else
#     PW=50
#     PH=50
#     if [[ $horizontal_count -gt 1 ]]; then
#       PW=$((50/((horizontal_count-1))))
#     fi
#     if [[ $vertical_count -gt 1 ]]; then
#       PH=$((50/((vertical_count-1))))
#     fi
#     echo "PW: $PW, PH: $PH"
#     tmux resize-pane -t "${ID}" -x ${PW}% -y ${PH}%
#   fi
# done

## Example 2: Absolute values: active panel (50%/50%), remaining share (50%/50% / number of panels)

# PANELS=$(tmux list-panes -F "#{pane_active}-#{pane_id}" | sort -nr)
# for PANEL in ${PANELS}; do
#   IFS=- read -r ACTIVE ID < <(echo "${PANEL}")
#   new_width=$((WINDOW_WIDTH/2))
#   new_height=$((WINDOW_HEIGHT/2))
#   # echo "DEBUG: win width: $WINDOW_WIDTH, pane width: $new_width"
#   # echo "DEBUG: win height: $WINDOW_HEIGHT, pane height: $new_height"
#   if [[ $ACTIVE -eq 1 ]]; then
#     tmux resize-pane -t "${ID}" -x ${new_width} -y ${new_height}
#   else
#     if [[ $horizontal_count -gt 1 ]]; then
#       new_width=$((new_width/((horizontal_count-1))))
#     fi
#     if [[ $vertical_count -gt 1 ]]; then
#       new_height=$((new_height/((vertical_count-1))))
#     fi
#     echo "DEBUG: PW: $new_width, PH: $new_height"
#     tmux resize-pane -t "${ID}" -x ${new_width} -y ${new_height}
#   fi
# done

## Example 3: Only change a panel if currently smaller than expected size?

# new_active_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
# new_active_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
# echo "DEBUG: window height x width: $WINDOW_HEIGHT x $WINDOW_WIDTH"
# echo "DEBUG: MIN ACTIVE pane height x width: $new_active_height x $new_active_width"

# new_inactive_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
# new_inactive_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
# if [[ $horizontal_count -gt 1 ]]; then
#   new_inactive_width=$((new_inactive_width/((horizontal_count-1))))
# fi
# if [[ $vertical_count -gt 1 ]]; then
#   new_inactive_height=$((new_active_height/((vertical_count-1))))
# fi
# echo "DEBUG: MIN INACTIVE pane height x width: $new_inactive_height x $new_inactive_width"
# echo ""
# echo ""

# PANELS=$(tmux list-panes -F "#{pane_active}-#{pane_id}-#{pane_width}-#{pane_height}" | sort -nr)
# for PANEL in ${PANELS}; do
#   IFS=- read -r ACTIVE ID WIDTH HEIGHT< <(echo "${PANEL}")

#   echo "DEBUG: $ID: (active: $ACTIVE) - current height x width: $HEIGHT x $WIDTH"

#   if [[ $ACTIVE -eq 1 ]]; then
#     if [[ $WIDTH -lt $new_active_width ]] || [[ $HEIGHT -lt $new_active_height ]]; then
#       echo "DEBUG: Active Resize"
#       tmux resize-pane -t "${ID}" -x ${new_active_width} -y ${new_active_height}
#     fi
#   else
#     if [[ $WIDTH -lt $new_inactive_width ]] || [[ $HEIGHT -lt $new_inactive_height ]]; then
#       echo "DEBUG: InActive Resize"
#       tmux resize-pane -t "${ID}" -x ${new_inactive_width} -y ${new_inactive_height}
#     fi
#   fi
# done

## Example 4: By changing a panel during the refresh loop it does not take into account the changes made to other panels in the current listing.

# new_active_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
# new_active_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
# echo "DEBUG: window height x width: $WINDOW_HEIGHT x $WINDOW_WIDTH"
# echo "DEBUG: MIN ACTIVE pane height x width: $new_active_height x $new_active_width"

# new_inactive_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
# new_inactive_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
# if [[ $horizontal_count -gt 1 ]]; then
#   new_inactive_width=$((new_inactive_width/((horizontal_count-1))))
# fi
# if [[ $vertical_count -gt 1 ]]; then
#   new_inactive_height=$((new_inactive_height/((vertical_count-1))))
# fi
# echo "DEBUG: MIN INACTIVE pane height x width: $new_inactive_height x $new_inactive_width"
# echo ""
# echo ""

# # Update active pane first

# IFS=- read -r ID WIDTH HEIGHT ACTIVE < <(tmux list-panes -F "#{pane_id}-#{pane_width}-#{pane_height}-#{pane_active}" | grep "1$")
# echo "DEBUG: $ID: (active: $ACTIVE) - current height x width: $HEIGHT x $WIDTH"

# if [[ $WIDTH -lt $new_active_width ]] || [[ $HEIGHT -lt $new_active_height ]]; then
#   echo "DEBUG: Active Resize: width: ${new_active_width}, height: ${new_active_height}"
#   tmux resize-pane -t "${ID}" -x ${new_active_width} -y ${new_active_height}
# fi

# # Update inactive panels

# PANELS=$(tmux list-panes -F "#{pane_id}-#{pane_width}-#{pane_height}-#{pane_active}" | grep "0$" | sort -nr)
# for PANEL in ${PANELS}; do
#   IFS=- read -r ID WIDTH HEIGHT ACTIVE< <(echo "${PANEL}")
#   echo "DEBUG: $ID: (active: $ACTIVE) - current height x width: $HEIGHT x $WIDTH"
#   if [[ $WIDTH -lt $new_inactive_width ]] || [[ $HEIGHT -lt $new_inactive_height ]]; then
#     echo "DEBUG: InActive Resize"
#     tmux resize-pane -t "${ID}" -x ${new_inactive_width} -y ${new_inactive_height}
#   fi
# done

## Example 5: review absolute values with enlarge by diff instead of setting x,y values

# new_active_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
# new_active_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
# echo "DEBUG: window height x width: $WINDOW_HEIGHT x $WINDOW_WIDTH"
# echo "DEBUG: MIN ACTIVE pane height x width: $new_active_height x $new_active_width"

# new_inactive_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
# new_inactive_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
# if [[ $horizontal_count -gt 1 ]]; then
#   new_inactive_width=$((new_inactive_width/((horizontal_count-1))))
# fi
# if [[ $vertical_count -gt 1 ]]; then
#   new_inactive_height=$((new_inactive_height/((vertical_count-1))))
# fi
# echo "DEBUG: MIN INACTIVE pane height x width: $new_inactive_height x $new_inactive_width"
# echo ""
# echo ""

# # Update active pane first

# IFS=- read -r ID WIDTH HEIGHT ACTIVE < <(tmux list-panes -F "#{pane_id}-#{pane_width}-#{pane_height}-#{pane_active}" | grep "1$")
# echo "DEBUG: $ID: (active: $ACTIVE) - current height x width: $HEIGHT x $WIDTH"

# if [[ $WIDTH -lt $new_active_width ]]; then
#   resize_left=$((new_active_width-WIDTH))
#   echo "DEBUG: Active Resize: width: ${new_active_width}: resize = L: ${resize_left}"
#   tmux resize-pane -t "${ID}" -L ${resize_left}
# fi

# if [[ $HEIGHT -lt $new_active_height ]]; then
#   resize_up=$((new_active_height-HEIGHT))
#   echo "DEBUG: Active Resize: height: ${new_active_height}: resize = U: ${resize_up}"
#   tmux resize-pane -t "${ID}" -U ${resize_up}
# fi

# Update inactive panels

# PANELS=$(tmux list-panes -F "#{pane_id}-#{pane_width}-#{pane_height}-#{pane_active}" | grep "0$" | sort -nr)
# for PANEL in ${PANELS}; do
#   IFS=- read -r ID WIDTH HEIGHT ACTIVE< <(echo "${PANEL}")
#   echo "DEBUG: $ID: (active: $ACTIVE) - current height x width: $HEIGHT x $WIDTH"
#   if [[ $WIDTH -lt $new_inactive_width ]] || [[ $HEIGHT -lt $new_inactive_height ]]; then
#     echo "DEBUG: InActive Resize"
#     tmux resize-pane -t "${ID}" -L $((new_inactive_width-WIDTH)) -U $((new_inactive_height-HEIGHT))
#   fi
# done

## Example 6: absolute value size checks before with percentages for changes, run panels in order

new_active_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
new_active_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
echo "DEBUG: window height x width: $WINDOW_HEIGHT x $WINDOW_WIDTH"
echo "DEBUG: MIN ACTIVE pane height x width: $new_active_height x $new_active_width"

new_inactive_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
new_inactive_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
if [[ $horizontal_count -gt 1 ]]; then
  new_inactive_width=$((new_inactive_width/((horizontal_count-1))))
fi
if [[ $vertical_count -gt 1 ]]; then
  new_inactive_height=$((new_inactive_height/((vertical_count-1))))
fi
echo "DEBUG: MIN INACTIVE pane height x width: $new_inactive_height x $new_inactive_width"
echo ""
echo ""




PANELS=$(tmux list-panes -F "#{pane_index}-#{pane_id}-#{pane_active}-#{pane_width}-#{pane_height}" | sort -n)
for PANEL in ${PANELS}; do
  IFS=- read -r INDEX ID ACTIVE WIDTH HEIGHT< <(echo "${PANEL}")

  if [[ $ACTIVE -eq 1 ]]; then
    if [[ $WIDTH -lt $new_active_width ]] || [[ $HEIGHT -lt $new_active_height ]]; then
      echo "DEBUG: Active Resize: width: ${new_active_width}, height: ${new_active_height}"
      tmux resize-pane -t "${ID}" -x 50% -y 50%
    fi
    continue
  fi

  # if [[ $WIDTH -lt $new_inactive_width ]] || [[ $HEIGHT -lt $new_inactive_height ]]; then
  PW=50
  PH=50
  if [[ $horizontal_count -gt 1 ]]; then
    PW=$((PW/((horizontal_count-1))))
  fi
  if [[ $vertical_count -gt 1 ]]; then
    PH=$((PH/((vertical_count-1))))
  fi
  echo "DEBUG: InActive Resize: $HEIGHT x $WIDTH = $PH % x $PW %"
  tmux resize-pane -t "${ID}" -x ${PW}% -y ${PH}%
  # fi
done


# Example 7: Stop any change which is not necassary
# Example 8: Deal with having horizontal and vertical panes




# PANELS=$(tmux list-panes -F "#{pane_id}-#{pane_active}-#{pane_width}-#{pane_height}" | sort -n)
# for PANEL in ${PANELS}; do
#   IFS=- read -r ID ACTIVE WIDTH HEIGHT< <(echo "${PANEL}")

#   if [[ $ACTIVE -eq 1 ]]; then
#     if [[ $WIDTH -lt $new_active_width ]] || [[ $HEIGHT -lt $new_active_height ]]; then
#       echo "DEBUG: Active Resize: width: ${new_active_width}, height: ${new_active_height}"
#       tmux resize-pane -t "${ID}" -x 50% -y 50%
#     fi
#   else
#     if [[ $WIDTH -lt $new_inactive_width ]] || [[ $HEIGHT -lt $new_inactive_height ]]; then
#       echo "DEBUG: InActive Resize"
#       PW=50
#       PH=50
#       if [[ $horizontal_count -gt 1 ]]; then
#         PW=$((PW/((horizontal_count-1))))
#       fi
#       if [[ $vertical_count -gt 1 ]]; then
#         PH=$((PH/((vertical_count-1))))
#       fi
#       echo "PW: $PW, PH: $PH"
#       tmux resize-pane -t "${ID}" -x ${PW}% -y ${PH}%
#     fi
#   fi
# done


























# PANELS=$(tmux list-panes -F "#{pane_id}-#{pane_width}-#{pane_height}-#{pane_active}" | grep "0$" | sort -nr)
# for PANEL in ${PANELS}; do
#   IFS=- read -r ID WIDTH HEIGHT ACTIVE< <(echo "${PANEL}")
#   echo "DEBUG: $ID: (active: $ACTIVE) - current height x width: $HEIGHT x $WIDTH"
#   if [[ $WIDTH -lt $new_inactive_width ]] || [[ $HEIGHT -lt $new_inactive_height ]]; then
#     echo "DEBUG: InActive Resize"
#     PW=50
#     PH=50
#     if [[ $horizontal_count -gt 1 ]]; then
#       PW=$((50/((horizontal_count-1))))
#     fi
#     if [[ $vertical_count -gt 1 ]]; then
#       PH=$((50/((vertical_count-1))))
#     fi
#     echo "PW: $PW, PH: $PH"
#     tmux resize-pane -t "${ID}" -x ${PW}% -y ${PH}%
#   fi
# done





# PANELS=$(tmux list-panes -F "#{pane_active}-#{pane_id}" | sort -nr)
# for PANEL in ${PANELS}; do
#   IFS=- read -r ACTIVE ID < <(echo "${PANEL}")
#   if [[ $ACTIVE -eq 1 ]]; then
#     tmux resize-pane -t "${ID}" -x 50% -y 50%
#   else
#     PW=50
#     PH=50
#     if [[ $horizontal_count -gt 1 ]]; then
#       PW=$((50/((horizontal_count-1))))
#     fi
#     if [[ $vertical_count -gt 1 ]]; then
#       PH=$((50/((vertical_count-1))))
#     fi
#     echo "PW: $PW, PH: $PH"
#     tmux resize-pane -t "${ID}" -x ${PW}% -y ${PH}%
#   fi
# done


















# done
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
