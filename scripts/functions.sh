#!/usr/bin/env bash

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
  min_active_width="${2}"

  IFS=- read -r active_height active_width < <(tmux list-panes -F "#{pane_height}-#{pane_width}" -f "#{m:1,#{pane_active}}")
  resize_height=false
  resize_width=false
  if [[ "${active_height}" -lt "${min_active_height}" ]]; then
    resize_height=true
  fi
  if [[ "${active_width}" -lt "${min_active_width}" ]]; then
    resize_width=true
  fi
  echo -n "${resize_height}-${resize_width}"
}

# Output basic debug statements to file or stdout
debug_log() {
  output="${1}"
  message="${2}"

  log_file="/tmp/tmux-pane-focus.log"

  debug=$(cat << EOF
$(date) > ${message}
EOF
)
  if [[ "${output}" == "file" ]]; then
    echo "${debug}" >> "${log_file}"
  else
    echo "${debug}"
  fi
}
