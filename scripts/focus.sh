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

IFS=- read -r resize_height resize_width active_height active_width< <(check_active_pane)
if [[ "${resize_height}" == "false" ]] && [[ "${resize_width}" == "false" ]]; then
    echo 'No resize required'
    exit 0
fi
echo "Active pane resize required: height=${resize_height} (${active_height} < ${MIN_ACTIVE_HEIGHT}), width=${resize_width} (${active_width} < ${MIN_ACTIVE_WIDTH})"

if [[ "${resize_height}" == "true" ]]; then
  CHECK_BOTTOM_PANES=$(tmux list-panes -F "#{pane_bottom}-#{pane_active}-#{pane_height}-#{pane_id}" | sort -n)

  for PANE in ${CHECK_BOTTOM_PANES}; do
    IFS=- read -r BOTTOM_HEIGHT ACTIVE HEIGHT ID < <(echo "${PANE}")

    if [[ "${ACTIVE}" -eq 1 ]]; then
      resize_percentage_pane ${ID} ${ACTIVE_PANE_HEIGHT_PERCENTAGE} 0
    else
      resize_percentage_pane ${ID} ${INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE} 0
    fi
  done
fi

if [[ "${resize_width}" == "true" ]]; then
  CHECK_RIGHT_PANES=$(tmux list-panes -F "#{pane_right}-#{pane_active}-#{pane_width}-#{pane_id}" | sort -n)

  for PANE in ${CHECK_RIGHT_PANES}; do
    IFS=- read -r RIGHT_WIDTH ACTIVE WIDTH ID < <(echo "${PANE}")

    if [[ "${ACTIVE}" -eq 1 ]]; then
      resize_percentage_pane ${ID} 0 ${ACTIVE_PANE_WIDTH_PERCENTAGE}
    else
      resize_percentage_pane ${ID} 0 ${INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE}
    fi
  done
fi
