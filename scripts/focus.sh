#!/usr/bin/env bash

IFS=- read -r WINDOW_HEIGHT WINDOW_WIDTH < <(tmux list-windows -F "#{window_height}-#{window_width}" -f "#{m:1,#{window_active}}")

PANE_COUNT=$(tmux list-panes | wc -l)
if [[ $PANE_COUNT -eq 1 ]]; then
  # Nothing to do
  exit 0
fi

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
  INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE=$(( (100 - ACTIVE_PANE_HEIGHT_PERCENTAGE) / HORIZONTAL_SPLIT_COUNT ))
  MIN_ACTIVE_HEIGHT=$((WINDOW_HEIGHT / (100 / ACTIVE_PANE_HEIGHT_PERCENTAGE) - HORIZONTAL_SPLIT_COUNT))
  MIN_INACTIVE_HEIGHT=$((WINDOW_HEIGHT / (100 / INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE)))
fi

if [[ VERTICAL_SPLIT_COUNT -eq 0 ]]; then
  # No splits so always will be 100%
  ACTIVE_PANE_WIDTH_PERCENTAGE=100
  INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE=100
  MIN_ACTIVE_WIDTH=$((WINDOW_WIDTH / (100 / ACTIVE_PANE_WIDTH_PERCENTAGE)))
  MIN_INACTIVE_WIDTH=$(((WINDOW_WIDTH / (100 / INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE))))
else
  ACTIVE_PANE_WIDTH_PERCENTAGE=50
  INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE=$(( (100 - ACTIVE_PANE_WIDTH_PERCENTAGE) / VERTICAL_SPLIT_COUNT ))
  MIN_ACTIVE_WIDTH=$((WINDOW_WIDTH / (100 / ACTIVE_PANE_WIDTH_PERCENTAGE) - VERTICAL_SPLIT_COUNT))
  MIN_INACTIVE_WIDTH=$((WINDOW_WIDTH / (100 / INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE)))
fi

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

# Functions
# ------------------------------------------------------------------------------------------------------------

resize_percentage_pane() {
  pane_id="${1}"
  pane_height="${2}"
  pane_width="${3}"

  if [[ ${pane_height} -gt 0 ]] && [[ ${pane_width} -gt 0 ]]; then
    echo "resizing pane: ${pane_id} - new height: ${pane_height}% - new width: ${pane_width}%"
    tmux resize-pane -t "${pane_id}" -y ${pane_height}% -x ${pane_width}%
  elif [[ $pane_height -gt 0 ]]; then
    echo "resizing pane: ${pane_id} - new height: ${pane_height}%"
    tmux resize-pane -t "${pane_id}" -y ${pane_height}%
  elif [[ $pane_width -gt 0 ]]; then
    echo "resizing pane: ${pane_id} - new width: ${pane_width}%"
    tmux resize-pane -t "${pane_id}" -x ${pane_width}%
  fi
}

# check_active_pane
# IFS=- read -r var1 var2 < <(check_active_pane)
check_active_pane() {
  IFS=- read -r ACTIVE_HEIGHT ACTIVE_WIDTH < <(tmux list-panes -F "#{pane_height}-#{pane_width}" -f "#{m:1,#{pane_active}}")
  RESIZE_HEIGHT_REQUIRED=false
  RESIZE_WIDTH_REQUIRED=false
  if [[ $ACTIVE_HEIGHT -lt $MIN_ACTIVE_HEIGHT ]]; then
    RESIZE_HEIGHT_REQUIRED=true
  elif [[ $ACTIVE_WIDTH -lt $MIN_ACTIVE_WIDTH ]]; then
    RESIZE_WIDTH_REQUIRED=true
  fi
  echo -n "${RESIZE_HEIGHT_REQUIRED}-${RESIZE_WIDTH_REQUIRED}-${ACTIVE_HEIGHT}-${ACTIVE_WIDTH}"
}

# Runtime
# ------------------------------------------------------------------------------------------------------------

# Currently a bug with trying to resize previous pane even if it was not small enough?

IFS=- read -r resize_height resize_width active_height active_width< <(check_active_pane)
if [[ "${resize_height}" == "false" ]] && [[ "${resize_width}" == "false" ]]; then
    echo 'No resize required'
    exit 0
fi
echo "Active pane resize required: height=${resize_height} (${active_height} < ${MIN_ACTIVE_HEIGHT}), width=${resize_width} (${active_width} < ${MIN_ACTIVE_WIDTH})"

if [[ "${resize_height}" == "true" ]]; then
  CHECK_BOTTOM_PANES=$(tmux list-panes -F "#{pane_bottom}-#{pane_active}-#{pane_height}-#{pane_id}" | sort -n)

  PREV_PANE=%-1
  ACTIVE_PANE=%-1
  i=0
  PANES_SINCE_ACTIVE=0

  for PANE in ${CHECK_BOTTOM_PANES}; do
    IFS=- read -r BOTTOM_HEIGHT ACTIVE HEIGHT ID < <(echo "${PANE}")
    i=$((i+1))
    echo "> ${i} (${ID}): ${ACTIVE} - ${HEIGHT} = ${MIN_ACTIVE_HEIGHT}|${MIN_INACTIVE_HEIGHT} > prev pane: ${PREV_PANE:1} - active pane: ${ACTIVE_PANE:1} > panes since active: ${PANES_SINCE_ACTIVE}"

    if [[ "${ACTIVE}" -eq 1 ]]; then
      ACTIVE_PANE="${ID}"

      # Resize active pane if first pane
      if [[ "${i}" -eq 1 ]] && [[ "${HEIGHT}" -lt "${MIN_ACTIVE_HEIGHT}" ]]; then
        echo "Resize active pane when first entry, id:${ID}, current H:${HEIGHT}, min:${MIN_ACTIVE_HEIGHT}"
        resize_percentage_pane ${ID} ${ACTIVE_PANE_HEIGHT_PERCENTAGE} 0
        break
      fi

      # Resize previous pane
      if [[ "${PREV_PANE:1}" -ne -1 ]]; then
        echo "Resize previous pane: ${PREV_PANE:1}"
        resize_percentage_pane ${PREV_PANE} ${INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE} 0
        break
      fi

      # Do not act on active panel as not first in index
      # continue
    fi

    if [[ "${ACTIVE_PANE:1}" -ne -1 ]]; then
      PANES_SINCE_ACTIVE=$((PANES_SINCE_ACTIVE+1))
    fi

    if [[ "${ACTIVE}" -eq 0 ]] && [[ "${HEIGHT}" -gt "${MIN_INACTIVE_HEIGHT}" ]]; then
      # echo "${HEIGHT} -gt ${MIN_INACTIVE_HEIGHT}"
      # Only set previous pane if it allows for resizing
      PREV_PANE="${ID}"
    fi

    if [[ "${ACTIVE_PANE:1}" -ne -1 ]] && [[ "${HEIGHT}" -gt "${MIN_INACTIVE_HEIGHT}" ]]; then
      echo "resize pane ID: ${ID}"
      resize_percentage_pane ${ID} ${INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE} 0
      break
    fi

    if [[ "${PANES_SINCE_ACTIVE}" -eq 2 ]]; then
      echo "Resize active pane as no pane adjacent big enough: i:${i} - pane since active: ${PANES_SINCE_ACTIVE}"
      resize_percentage_pane ${ACTIVE_PANE} ${ACTIVE_PANE_HEIGHT_PERCENTAGE} 0
      break
    fi
  done
fi

# if [[ "${resize_width}" == "true" ]]; then
#   CHECK_RIGHT_PANES=$(tmux list-panes -F "#{pane_right}-#{pane_active}-#{pane_width}-#{pane_id}" | sort -n)

#   PREV_PANE=%-1
#   ACTIVE_PANE=%-1
#   i=0

#   for PANE in ${CHECK_RIGHT_PANES}; do
#     IFS=- read -r RIGHT_WIDTH ACTIVE WIDTH ID < <(echo "${PANE}")
#     i=$((i+1))
#     # echo "index: ${i}: ${ACTIVE} - ${WIDTH} = ${MIN_ACTIVE_WIDTH}|${MIN_INACTIVE_WIDTH}"

#     if [[ "${ACTIVE}" -eq 1 ]] && [[ "${i}" -eq 1 ]] && [[ "${WIDTH}" -lt "${MIN_ACTIVE_WIDTH}" ]]; then
#       echo "Resize active pane when first entry, id:${ID}, current W:${WIDTH}, min:${MIN_ACTIVE_WIDTH}"
#       resize_percentage_pane ${ID} 0 ${ACTIVE_PANE_WIDTH_PERCENTAGE}
#     fi

#     if [[ "${ACTIVE}" -eq 0 ]] && [[ "${WIDTH}" -gt "${INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE}" ]]; then
#       PREV_PANE="${ID}"
#     fi

#     if [[ "${ACTIVE}" -eq 1 ]]; then
#       ACTIVE_PANE="${ID}"
#       if [[ "${PREV_PANE:1}" -ne -1 ]]; then
#         echo "Resize previous pane: ${PREV_PANE:1}"
#         resize_percentage_pane ${PREV_PANE} 0 ${MIN_INACTIVE_WIDTH}
#         break
#       fi
#       # Do not act on active panel as not first in index
#       continue
#     fi

#     if [[ "${ACTIVE_PANE:1}" -ne -1 ]] && [[ "${WIDTH}" -gt "${MIN_INACTIVE_WIDTH}" ]]; then
#       echo "resize pane ID: ${ID}"
#       resize_percentage_pane ${ID} 0 ${INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE}
#       break
#     fi
#   done
# fi

exit 0













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
  # tmux resize-pane -t "${ID}" -x ${MIN_INACTIVE_WIDTH}
  resize_percentage_pane ${ID} 0 ${MIN_INACTIVE_WIDTH}
done

for ID in "${INACTIVE_RESIZE_AVAILABLE_HEIGHT[@]}"; do
  echo "RESIZE ${ID} HEIGHT to ${MIN_INACTIVE_HEIGHT}"
  # tmux resize-pane -t "${ID}" -y ${MIN_INACTIVE_HEIGHT}
  resize_percentage_pane "${ID}" "${MIN_INACTIVE_HEIGHT}" 0
done
