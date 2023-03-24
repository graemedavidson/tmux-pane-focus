#!/usr/bin/env bash

IFS=- read -r WINDOW_HEIGHT WINDOW_WIDTH < <(tmux list-windows -F "#{window_height}-#{window_width}" -f "#{m:1,#{window_active}}")

PANE_COUNT=$(tmux list-panes | wc -l)
# if [[ $PANE_COUNT -eq 1 ]]; then
#   # Nothing to do
#   exit 0
# fi

# ----------------------------------------------------------------------------------------------------------------------------
# Horizontal and Vertical panel counts.

# PANEL_SPLIT_SIZE=1    # The size on screen of a split bar.

VERTICAL_SPLIT_COUNT=0
LAST_RIGHT_VAL=0
RIGHT_PANES=$(tmux list-panes -F "#{pane_right}" | sort -n)
for PT in ${RIGHT_PANES}; do
  IFS=- read -r PAN_RIGHT < <(echo "${PT}")
  if [[ $PAN_RIGHT -gt LAST_RIGHT_VAL ]]; then
    ((VERTICAL_SPLIT_COUNT=VERTICAL_SPLIT_COUNT+1))
    LAST_RIGHT_VAL=$PAN_RIGHT
  fi
done

HORIZONTAL_SPLIT_COUNT=0
LAST_BOTTOM_VAL=0
BOTTOM_PANES=$(tmux list-panes -F "#{pane_bottom}" | sort -n)
for PT in ${BOTTOM_PANES}; do
  IFS=- read -r PAN_BOTTOM < <(echo "${PT}")
  if [[ $PAN_BOTTOM -gt LAST_BOTTOM_VAL ]]; then
    ((HORIZONTAL_SPLIT_COUNT=HORIZONTAL_SPLIT_COUNT+1))
    LAST_BOTTOM_VAL=$PAN_BOTTOM
  fi
done

if [[ HORIZONTAL_SPLIT_COUNT -ge 1 ]]; then
  HORIZONTAL_SPLIT_COUNT=$((HORIZONTAL_SPLIT_COUNT-1))
fi
if [[ VERTICAL_SPLIT_COUNT -ge 1 ]]; then
  VERTICAL_SPLIT_COUNT=$((VERTICAL_SPLIT_COUNT-1))
fi

# ----------------------------------------------------------------------------------------------------------------------------
# Active and Inactive panel sizes

# Percentages based on 100%
# Dividing under 100 to work with integers

if [[ HORIZONTAL_SPLIT_COUNT -eq 0 ]]; then
  # No splits so always will be 100%
  ACTIVE_PANE_HEIGHT_PERCENTAGE=100
  INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE=100
  MIN_ACTIVE_HEIGHT=$((WINDOW_HEIGHT / (100 / ACTIVE_PANE_HEIGHT_PERCENTAGE)))
  MIN_INACTIVE_HEIGHT=$(((WINDOW_HEIGHT / (100 / INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE))))
else
  ACTIVE_PANE_HEIGHT_PERCENTAGE=50
  INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE=$((100 - ACTIVE_PANE_HEIGHT_PERCENTAGE))
  MIN_ACTIVE_HEIGHT=$((WINDOW_HEIGHT / (100 / ACTIVE_PANE_HEIGHT_PERCENTAGE)))
  MIN_INACTIVE_HEIGHT=$(((WINDOW_HEIGHT / (100 / INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE)) / (HORIZONTAL_SPLIT_COUNT) ))
fi

if [[ VERTICAL_SPLIT_COUNT -eq 0 ]]; then
  # No splits so always will be 100%
  ACTIVE_PANE_WIDTH_PERCENTAGE=100
  INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE=100
  MIN_ACTIVE_WIDTH=$((WINDOW_WIDTH / (100 / ACTIVE_PANE_WIDTH_PERCENTAGE)))
  MIN_INACTIVE_WIDTH=$(((WINDOW_WIDTH / (100 / INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE))))
else
  ACTIVE_PANE_WIDTH_PERCENTAGE=50
  INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE=$((100 - ACTIVE_PANE_WIDTH_PERCENTAGE))
  MIN_ACTIVE_WIDTH=$((WINDOW_WIDTH / (100 / ACTIVE_PANE_WIDTH_PERCENTAGE)))
  MIN_INACTIVE_WIDTH=$(((WINDOW_WIDTH / (100 / INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE)) / (VERTICAL_SPLIT_COUNT) ))
fi

# -1 to allow for a single panel not needing adjustment
# MIN_ACTIVE_WIDTH=$((WINDOW_WIDTH / 100 * DEFAULT_ACTIVE_PANEL_WIDTH - (vertical_count - 1)))
# MIN_ACTIVE_HEIGHT=$((WINDOW_HEIGHT / 100 * DEFAULT_ACTIVE_PANEL_HEIGHT - (horizontal_count - 1)))
# if [[ $horizontal_count -gt 1 ]]; then
#   MIN_INACTIVE_WIDTH=$((min_inactive_width/((horizontal_count-1))))
# fi
# if [[ $vertical_count -gt 1 ]]; then
#   MIN_INACTIVE_HEIGHT=$((min_inactive_height/((vertical_count-1))))
# fi

# min_inactive_width=$((WINDOW_WIDTH/2-(PANE_COUNT-1)))
# min_inactive_height=$((WINDOW_HEIGHT/2-(PANE_COUNT-1)))
# if [[ $horizontal_count -gt 1 ]]; then
#   min_inactive_width=$((min_inactive_width/((horizontal_count-1))))
# fi
# if [[ $vertical_count -gt 1 ]]; then
#   min_inactive_height=$((min_inactive_height/((vertical_count-1))))
# fi

# ----------------------------------------------------------------------------------------------------------------------------
# DEBUG

echo "horizontal splits (-): ${HORIZONTAL_SPLIT_COUNT}, vertical splits (|): ${VERTICAL_SPLIT_COUNT}"
echo "-----------------------------------------------------------------"
echo "default active pane (%): H: $ACTIVE_PANE_HEIGHT_PERCENTAGE x W: $ACTIVE_PANE_WIDTH_PERCENTAGE"
echo "default inactive pane (%): H: $INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE x W: $INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE"
echo "-----------------------------------------------------------------"
echo "Window dimensions: H:$WINDOW_HEIGHT x W:$WINDOW_WIDTH"
echo "-----------------------------------------------------------------"
echo "minimum active dimensions: H:$MIN_ACTIVE_HEIGHT x W:$MIN_ACTIVE_WIDTH"
echo "minimum inactive dimensions (taking into account number of panes): H:$MIN_INACTIVE_HEIGHT x W:$MIN_INACTIVE_WIDTH"

echo "-----------------------------------------------------------------"
echo "-----------------------------------------------------------------"
# ----------------------------------------------------------------------------------------------------------------------------

# Example: Controlled changes
# 1. determine if active pane needs resizing
# 2. get inactive panes > min size
# 3. resize panel
# 4. check active pane (as above might of changed it to fit)
# 5. recursive step 3 and 4
# 6. if no inactive panels left to resize, resize active panel
#
#
#

# Determine if the active pane requires a resize and in which orientation.
IFS=- read -r ACTIVE_HEIGHT ACTIVE_WIDTH ACTIVE_ID < <(tmux list-panes -F "#{pane_height}-#{pane_width}-#{pane_id}" -f "#{m:1,#{pane_active}}")
RESIZE_HEIGHT_REQUIRED=false
RESIZE_WIDTH_REQUIRED=false
if [[ $ACTIVE_HEIGHT -lt $MIN_ACTIVE_HEIGHT ]]; then
  echo "DEBUG: Active Pane Resize: Height - current: $ACTIVE_HEIGHT - min: $MIN_ACTIVE_HEIGHT"
  # RESIZE_HEIGHT_REQUIRED=true
  # tmux resize-pane -t "${ACTIVE_ID}" -y ${ACTIVE_PANE_HEIGHT_PERCENTAGE}%
elif [[ $ACTIVE_WIDTH -lt $MIN_ACTIVE_WIDTH ]]; then
  echo "DEBUG: Active Pane Resize: Width - current: $ACTIVE_WIDTH - min: $MIN_ACTIVE_WIDTH"
  # RESIZE_WIDTH_REQUIRED=true
  # tmux resize-pane -t "${ACTIVE_ID}" -y ${ACTIVE_PANE_WIDTH_PERCENTAGE}%
else
  echo "DEBUG: No Resize required"
fi



echo "-----------------------------------------------------------------"
echo "-----------------------------------------------------------------"

# Determine which inactive panes can be resized and which orientation

INACTIVE_RESIZE_AVAILABLE_WIDTH=()
INACTIVE_RESIZE_AVAILABLE_HEIGHT=()

INACTIVE_PANES=$(tmux list-panes -F "#{pane_id}-#{pane_height}-#{pane_width}" -f "#{m:0,#{pane_active}}")
for PANE in ${INACTIVE_PANES}; do
  IFS=- read -r ID HEIGHT WIDTH < <(echo "${PANE}")

  if [[ $HEIGHT -gt $MIN_INACTIVE_HEIGHT ]]; then
    echo "DEBUG: INACTIVE Resize for: ${ID} - Height: current: $HEIGHT, min: ${MIN_INACTIVE_HEIGHT}"
    INACTIVE_RESIZE_AVAILABLE_HEIGHT+=("${ID}")
  fi
  if [[ $WIDTH -gt $MIN_INACTIVE_WIDTH ]]; then
    echo "DEBUG: INACTIVE Resize for: ${ID} - Width: current: $WIDTH, min: ${MIN_INACTIVE_WIDTH}"
    INACTIVE_RESIZE_AVAILABLE_WIDTH+=("${ID}")
  fi
done

echo "Inactive panes larger than minimum height: ${INACTIVE_RESIZE_AVAILABLE_HEIGHT[*]}"
echo "Inactive panes larger than minimum width: ${INACTIVE_RESIZE_AVAILABLE_WIDTH[*]}"


echo "-----------------------------------------------------------------"
echo "-----------------------------------------------------------------"

# Can either
# - resize the pane closest to the new active pane which requires figuring out proximity
# - resize all
# - resize first based on ordering:
#   - id (hightest/lowest)
#   - index (hightest/lowest)

for ID in "${INACTIVE_RESIZE_AVAILABLE_WIDTH[@]}"; do
  echo "RESIZE ${ID} WIDTH to ${MIN_INACTIVE_WIDTH}"
  tmux resize-pane -t "${ID}" -x ${MIN_INACTIVE_WIDTH}
done

for ID in "${INACTIVE_RESIZE_AVAILABLE_HEIGHT[@]}"; do
  echo "RESIZE ${ID} HEIGHT to ${MIN_INACTIVE_HEIGHT}"
  tmux resize-pane -t "${ID}" -y ${MIN_INACTIVE_HEIGHT}
done


exit 0


echo "-----------------------------------------------------------------"
echo "-----------------------------------------------------------------"









exit 0


# PANELS=$(tmux list-panes -F "#{pane_active}-#{pane_id}" | sort -n)
for PANEL in ${PANELS}; do
  IFS=- read -r INDEX ID < <(echo "${PANEL}")

  # Get each panes current height x width
  IFS=- read -r ACTIVE HEIGHT WIDTH < <(tmux list-panes -F "#{pane_active}-#{pane_height}-#{pane_width}" -f "#{m:${ID},#{pane_id}}")

  if [[ $ACTIVE -eq 1 ]]; then
    if [[ $HEIGHT -lt $min_active_height ]]; then
      echo "DEBUG: Active Resize Height for: ${ID} - current: $HEIGHT, min: ${min_active_height}"
      tmux resize-pane -t "${ID}" -y 50%
    fi
    if [[ $WIDTH -lt $min_active_width ]]; then
      echo "DEBUG: Active Resize Width for: ${ID} - current: $WIDTH, min: ${min_active_width}"
      tmux resize-pane -t "${ID}" -x 50%
    fi
    continue
  fi

  # Inactive Panels
  # PH=50
  # if [[ $horizontal_count -gt 1 ]]; then
  #   PH=$((PW/((horizontal_count-1))))
  # fi
  # echo "DEBUG: InActive Resize Height for: ${ID} - current: $HEIGHT, min: ${min_inactive_height}, resize %: ${PH}"
  # tmux resize-pane -t "${ID}" -y ${PH}%

  # PW=50
  # if [[ $vertical_count -gt 1 ]]; then
  #   PW=$((PH/((vertical_count-1))))
  # fi
  # echo "DEBUG: InActive Resize Width for: ${ID} - current: $WIDTH, min: ${min_inactive_width}, resize %: ${PW}"
  # tmux resize-pane -t "${ID}" -x ${PW}%

  # Inactive Panels
  # if [[ $HEIGHT -lt $min_inactive_height ]]; then
  #   PH=50
  #   if [[ $horizontal_count -gt 1 ]]; then
  #     PW=$((PW/((horizontal_count-1))))
  #   fi
  #   echo "DEBUG: InActive Resize Height for: ${ID} - current: $HEIGHT, min: ${min_inactive_height}, resize %: ${PH}"
  #   tmux resize-pane -t "${ID}" -y ${PH}%
  # fi
  # if [[ $WIDTH -lt $min_inactive_width ]]; then
  #   PW=50
  #   if [[ $vertical_count -gt 1 ]]; then
  #     PH=$((PH/((vertical_count-1))))
  #   fi
  #   echo "DEBUG: InActive Resize Width for: ${ID} - current: $WIDTH, min: ${min_inactive_width}, resize %: ${PW}"
  #   tmux resize-pane -t "${ID}" -x ${PW}%
  # fi
done








# PANELS=$(tmux list-panes -F "#{pane_index}-#{pane_id}" | sort -n)
# # PANELS=$(tmux list-panes -F "#{pane_active}-#{pane_id}" | sort -n)
# for PANEL in ${PANELS}; do
#   IFS=- read -r INDEX ID < <(echo "${PANEL}")

#   # Get each panes current height x width
#   IFS=- read -r ACTIVE HEIGHT WIDTH < <(tmux list-panes -F "#{pane_active}-#{pane_height}-#{pane_width}" -f "#{m:${ID},#{pane_id}}")

#   if [[ $ACTIVE -eq 1 ]]; then
#     if [[ $HEIGHT -lt $min_active_height ]]; then
#       echo "DEBUG: Active Resize Height for: ${ID} - current: $HEIGHT, min: ${min_active_height}"
#       tmux resize-pane -t "${ID}" -y 50%
#     fi
#     if [[ $WIDTH -lt $min_active_width ]]; then
#       echo "DEBUG: Active Resize Width for: ${ID} - current: $WIDTH, min: ${min_active_width}"
#       tmux resize-pane -t "${ID}" -x 50%
#     fi
#     continue
#   fi

#   # Inactive Panels
#   # PH=50
#   # if [[ $horizontal_count -gt 1 ]]; then
#   #   PH=$((PW/((horizontal_count-1))))
#   # fi
#   # echo "DEBUG: InActive Resize Height for: ${ID} - current: $HEIGHT, min: ${min_inactive_height}, resize %: ${PH}"
#   # tmux resize-pane -t "${ID}" -y ${PH}%

#   # PW=50
#   # if [[ $vertical_count -gt 1 ]]; then
#   #   PW=$((PH/((vertical_count-1))))
#   # fi
#   # echo "DEBUG: InActive Resize Width for: ${ID} - current: $WIDTH, min: ${min_inactive_width}, resize %: ${PW}"
#   # tmux resize-pane -t "${ID}" -x ${PW}%

#   # Inactive Panels
#   # if [[ $HEIGHT -lt $min_inactive_height ]]; then
#   #   PH=50
#   #   if [[ $horizontal_count -gt 1 ]]; then
#   #     PW=$((PW/((horizontal_count-1))))
#   #   fi
#   #   echo "DEBUG: InActive Resize Height for: ${ID} - current: $HEIGHT, min: ${min_inactive_height}, resize %: ${PH}"
#   #   tmux resize-pane -t "${ID}" -y ${PH}%
#   # fi
#   # if [[ $WIDTH -lt $min_inactive_width ]]; then
#   #   PW=50
#   #   if [[ $vertical_count -gt 1 ]]; then
#   #     PH=$((PH/((vertical_count-1))))
#   #   fi
#   #   echo "DEBUG: InActive Resize Width for: ${ID} - current: $WIDTH, min: ${min_inactive_width}, resize %: ${PW}"
#   #   tmux resize-pane -t "${ID}" -x ${PW}%
#   # fi
# done


exit 0


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




# PANELS=$(tmux list-panes -F "#{pane_index}-#{pane_id}-#{pane_active}-#{pane_width}-#{pane_height}" | sort -n)
# for PANEL in ${PANELS}; do
#   IFS=- read -r INDEX ID ACTIVE WIDTH HEIGHT< <(echo "${PANEL}")

#   if [[ $ACTIVE -eq 1 ]]; then
#     if [[ $WIDTH -lt $new_active_width ]] || [[ $HEIGHT -lt $new_active_height ]]; then
#       echo "DEBUG: Active Resize: width: ${new_active_width}, height: ${new_active_height}"
#       tmux resize-pane -t "${ID}" -x 50% -y 50%
#     fi
#     continue
#   fi

#   # if [[ $WIDTH -lt $new_inactive_width ]] || [[ $HEIGHT -lt $new_inactive_height ]]; then
#   PW=50
#   PH=50
#   if [[ $horizontal_count -gt 1 ]]; then
#     PW=$((PW/((horizontal_count-1))))
#   fi
#   if [[ $vertical_count -gt 1 ]]; then
#     PH=$((PH/((vertical_count-1))))
#   fi
#   echo "DEBUG: InActive Resize: $HEIGHT x $WIDTH = $PH % x $PW %"
#   tmux resize-pane -t "${ID}" -x ${PW}% -y ${PH}%
#   # fi
# done

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

# Example 7: get panel list and then loop through getting latest heightxwidth to account for previous changes

# PANELS=$(tmux list-panes -F "#{pane_index}-#{pane_id}" | sort -n)
# # PANELS=$(tmux list-panes -F "#{pane_active}-#{pane_id}" | sort -n)
# for PANEL in ${PANELS}; do
#   IFS=- read -r INDEX ID < <(echo "${PANEL}")

#   # Get each panes current height x width
#   IFS=- read -r ACTIVE HEIGHT WIDTH < <(tmux list-panes -F "#{pane_active}-#{pane_height}-#{pane_width}" -f "#{m:${ID},#{pane_id}}")

#   if [[ $ACTIVE -eq 1 ]]; then
#     if [[ $HEIGHT -lt $min_active_height ]]; then
#       echo "DEBUG: Active Resize Height for: ${ID} - current: $HEIGHT, min: ${min_active_height}"
#       tmux resize-pane -t "${ID}" -y 50%
#     fi
#     if [[ $WIDTH -lt $min_active_width ]]; then
#       echo "DEBUG: Active Resize Width for: ${ID} - current: $WIDTH, min: ${min_active_width}"
#       tmux resize-pane -t "${ID}" -x 50%
#     fi
#     continue
#   fi

#   # Inactive Panels
#   # PH=50
#   # if [[ $horizontal_count -gt 1 ]]; then
#   #   PH=$((PW/((horizontal_count-1))))
#   # fi
#   # echo "DEBUG: InActive Resize Height for: ${ID} - current: $HEIGHT, min: ${min_inactive_height}, resize %: ${PH}"
#   # tmux resize-pane -t "${ID}" -y ${PH}%

#   # PW=50
#   # if [[ $vertical_count -gt 1 ]]; then
#   #   PW=$((PH/((vertical_count-1))))
#   # fi
#   # echo "DEBUG: InActive Resize Width for: ${ID} - current: $WIDTH, min: ${min_inactive_width}, resize %: ${PW}"
#   # tmux resize-pane -t "${ID}" -x ${PW}%

#   # Inactive Panels
#   # if [[ $HEIGHT -lt $min_inactive_height ]]; then
#   #   PH=50
#   #   if [[ $horizontal_count -gt 1 ]]; then
#   #     PW=$((PW/((horizontal_count-1))))
#   #   fi
#   #   echo "DEBUG: InActive Resize Height for: ${ID} - current: $HEIGHT, min: ${min_inactive_height}, resize %: ${PH}"
#   #   tmux resize-pane -t "${ID}" -y ${PH}%
#   # fi
#   # if [[ $WIDTH -lt $min_inactive_width ]]; then
#   #   PW=50
#   #   if [[ $vertical_count -gt 1 ]]; then
#   #     PH=$((PH/((vertical_count-1))))
#   #   fi
#   #   echo "DEBUG: InActive Resize Width for: ${ID} - current: $WIDTH, min: ${min_inactive_width}, resize %: ${PW}"
#   #   tmux resize-pane -t "${ID}" -x ${PW}%
#   # fi
# done

# Example 8: Absolute changes based on location of panel
#
# determine where a panel is?
#







# Example 9: Stop any change which is not necassary
# Example 10: Deal with having horizontal and vertical panes

















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
