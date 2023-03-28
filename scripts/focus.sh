#!/usr/bin/env bash

# Settings
# ------------------------------------------------------------------------------------------------------------

PANE_COUNT=$(tmux list-panes | wc -l)
if [[ $PANE_COUNT -eq 1 ]]; then
  exit 0
fi

IFS=- read -r WINDOW_HEIGHT WINDOW_WIDTH < <(tmux list-windows -F "#{window_height}-#{window_width}" -f "#{m:1,#{window_active}}")

# Functions
# ------------------------------------------------------------------------------------------------------------

# Return split panel counts.
#
# right = vertical, bottom = horizontal
#
# Parameter(s):
# - direction (string): split type (right|bottom)
#
# Return(s):
# - split_count (number): Number of splits on direction
get_split_count() {
  direction="${1}"

  split_count=0
  last_val=0

  # sort ensures panes listed correctly, left -> right, top -> bottom
  panes=$(tmux list-panes -F "#{pane_${direction}}" | sort -n)

  for pane in ${panes}; do
    IFS=- read -r pane_direction_val < <(echo "${pane}")
    if [[ "${pane_direction_val}" -gt "${last_val}" ]]; then
      ((split_count=split_count+1))
      last_val=$pane_direction_val
    fi
  done

  # Decrement by 1 to account for single pane not having a split
  if [[ split_count -ge 1 ]]; then
    split_count=$((split_count-1))
  fi

  echo "${split_count}"
}

# Return settings for pane sizes
#
# To account for bash integer maths 100 is used as a whole percentage as base.
#
# Parameter(s):
# - split_count (number): number of vertical (|) or horizontal (-) splits/panes
# - window_size (number): the absolute height or width
#
# Return(s):
# - active_percentage (number): Percentage of screen size given to active panel
# - inactive_percentage (number): Percentage given to remaining inactive panels
# - min_active (number): Absolute value for active pane size
# - min_inactive (number): Absolute value for inactive pane size
get_settings() {
  split_count="${1}"
  window_size="${2}"

  # ToDo: allow this to set via a user input
  # active_pane_percentage="50"

  # No splits so always will be 100%
  if [[ "${split_count}" -eq 0 ]]; then
    active_percentage=100
    inactive_percentage=100

    min_active=$((window_size / (100 / active_percentage)))
    min_inactive=$((window_size / (100 / inactive_percentage)))
  else
    active_percentage=50
    inactive_percentage=$(( (100 - active_percentage) / split_count ))
    min_active=$((window_size / (100 / active_percentage) - split_count))
    min_inactive=$((window_size / (100 / inactive_percentage)))
  fi

  echo "${active_percentage}-${inactive_percentage}-${min_active}-${min_inactive}"
}

# Resize a tmux pane by percentage
#
# Parameter(s):
# - pane_id (string): unique id for tmux pane to be changed
# - pane_height (integer): height value to change pane to
# - pane_width (integer): width value to change pane to
resize_pane() {
  pane_id="${1}"
  pane_height="${2}"
  pane_width="${3}"

  if [[ ${pane_height} -gt 0 ]] && [[ ${pane_width} -gt 0 ]]; then
    tmux resize-pane -t "${pane_id}" -y "${pane_height}%" -x "${pane_width}%"
  elif [[ $pane_height -gt 0 ]]; then
    tmux resize-pane -t "${pane_id}" -y "${pane_height}%"
  elif [[ $pane_width -gt 0 ]]; then
    tmux resize-pane -t "${pane_id}" -x "${pane_width}%"
  fi
}

# Check if the active pane requires resize
#
# Parameter(s):
# - min_active_height (integer): absolute value for minimum height of active pane
# - min_active_width (integer): absolute value for minimum width of active pane
#
# Return(s):
# - resize_height (string): true|false value indicating if resize required
# - resize_width (string): true|false value indicating if resize required
check_active_pane() {
  min_active_height="${1}"
  min_active_width="${3}"

  IFS=- read -r active_height active_width < <(tmux list-panes -F "#{pane_height}-#{pane_width}" -f "#{m:1,#{pane_active}}")
  resize_height=false
  resize_width=false
  if [[ "${active_height}" -lt "${min_active_height}" ]]; then
    resize_height=true
  elif [[ "${active_width}" -lt "${min_active_width}" ]]; then
    resize_width=true
  fi
  echo -n "${resize_height}-${resize_width}"
}

# Output basic debug statements to file or stdout
debug_log() {
  output="${1}"

  log_file="/tmp/tmux-pane-focus.log"

  debug=$(cat << EOF
$(date) > horizontal splits (-): ${HORIZONTAL_SPLIT_COUNT}, vertical splits (|): ${VERTICAL_SPLIT_COUNT}
$(date) > default active pane: H:${ACTIVE_PANE_HEIGHT_PERCENTAGE}% x W:${ACTIVE_PANE_WIDTH_PERCENTAGE}%
$(date) > default inactive pane: H:${INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE}% x W:${INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE}%
$(date) > Window dimensions: H:${WINDOW_HEIGHT} x W:${WINDOW_WIDTH}
$(date) > minimum active dimensions: H:${MIN_ACTIVE_HEIGHT} x W:${MIN_ACTIVE_WIDTH}
$(date) > minimum inactive dimensions (taking into account number of splits): H:${MIN_INACTIVE_HEIGHT} x W:${MIN_INACTIVE_WIDTH}
EOF
)
  if [[ "${output}" == "file" ]]; then
    echo "${debug}" >> "${log_file}"
  else
    echo "${debug}"
  fi
}

# Runtime
# ------------------------------------------------------------------------------------------------------------

read -r VERTICAL_SPLIT_COUNT< <(get_split_count "right")
read -r HORIZONTAL_SPLIT_COUNT< <(get_split_count "bottom")

IFS=- read -r ACTIVE_PANE_WIDTH_PERCENTAGE INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE MIN_ACTIVE_WIDTH MIN_INACTIVE_WIDTH< <(get_settings "${VERTICAL_SPLIT_COUNT}" "${WINDOW_WIDTH}")
IFS=- read -r ACTIVE_PANE_HEIGHT_PERCENTAGE INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE MIN_ACTIVE_HEIGHT MIN_INACTIVE_HEIGHT< <(get_settings "${HORIZONTAL_SPLIT_COUNT}" "${WINDOW_HEIGHT}")

IFS=- read -r resize_height resize_width< <(check_active_pane "${MIN_ACTIVE_HEIGHT}" "${MIN_ACTIVE_WIDTH}")
if [[ "${resize_height}" == "false" ]] && [[ "${resize_width}" == "false" ]]; then
    exit 0
fi

debug_log "file"

if [[ "${resize_height}" == "true" ]]; then
  horizontal_panes=$(tmux list-panes -F "#{pane_bottom}-#{pane_active}-#{pane_id}" | sort -n)

  for pane in ${horizontal_panes}; do
    IFS=- read -r _ active id < <(echo "${pane}")

    if [[ "${active}" -eq 1 ]]; then
      resize_pane "${id}" "${ACTIVE_PANE_HEIGHT_PERCENTAGE}" 0
    else
      resize_pane "${id}" "${INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE}" 0
    fi
  done
fi

if [[ "${resize_width}" == "true" ]]; then
  vertical_panes=$(tmux list-panes -F "#{pane_right}-#{pane_active}-#{pane_id}" | sort -n)

  for pane in ${vertical_panes}; do
    IFS=- read -r _ active id < <(echo "${pane}")

    if [[ "${active}" -eq 1 ]]; then
      resize_pane "${id}" 0 "${ACTIVE_PANE_WIDTH_PERCENTAGE}"
    else
      resize_pane "${id}" 0 "${INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE}"
    fi
  done
fi
