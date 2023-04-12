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
  local panes="${1}"

  split_count=0
  last_val=0

  for pane in ${panes}; do
    IFS=- read -r pane_direction_val _ _ _ _ _< <(echo "${pane}")
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

# # Return split panel counts.
# #
# # right = vertical, bottom = horizontal
# #
# # Parameter(s):
# # - direction (string): split type (right|bottom)
# #
# # Return(s):
# # - split_count (number): Number of splits on direction
# get_split_count() {
#   direction="${1}"

#   split_count=0
#   last_val=0

#   # sort ensures panes listed correctly, left -> right, top -> bottom
#   panes=$(tmux list-panes -F "#{pane_${direction}}" | sort -n)

#   for pane in ${panes}; do
#     IFS=- read -r pane_direction_val < <(echo "${pane}")
#     if [[ "${pane_direction_val}" -gt "${last_val}" ]]; then
#       ((split_count=split_count+1))
#       last_val=$pane_direction_val
#     fi
#   done

#   # Decrement by 1 to account for single pane not having a split
#   if [[ split_count -ge 1 ]]; then
#     split_count=$((split_count-1))
#   fi

#   echo "${split_count}"
# }

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
  active_percentage="${3}"

  # No splits so always will be 100%
  if [[ "${split_count}" -eq 0 ]]; then
    # Overwrite active as no splits
    active_percentage=100
    inactive_percentage=100
    min_active="${window_size}"
    min_inactive="${window_size}"
  else
    inactive_percentage=$(((100 - active_percentage) / split_count))
    min_active=$(((window_size * active_percentage / 100)))
    min_inactive=$(((window_size * inactive_percentage / 100) - split_count))
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
    tmux resize-pane -t "${pane_id}" -y "${pane_height}" -x "${pane_width}"
  elif [[ $pane_height -gt 0 ]]; then
    tmux resize-pane -t "${pane_id}" -y "${pane_height}"
  elif [[ $pane_width -gt 0 ]]; then
    tmux resize-pane -t "${pane_id}" -x "${pane_width}"
  fi
}

# get values of active pane
#
# parameter(s):
# - min_active_height (integer): absolute value for minimum height of active pane
# - min_active_width (integer): absolute value for minimum width of active pane
#
# return(s):
# - resize_height (string): true|false value indicating if resize required
# - resize_width (string): true|false value indicating if resize required
# - top
# - bottom
# - left
# - right
get_active_pane() {
  local min_height="${1}"
  local min_width="${2}"

  IFS=- read -r id height width top bottom left right< <(tmux list-panes -F "#{pane_id}-#{pane_height}-#{pane_width}-#{pane_top}-#{pane_bottom}-#{pane_left}-#{pane_right}" -f "#{m:1,#{pane_active}}")
  resize_height=false
  resize_width=false
  if [[ "${height}" -lt "${min_height}" ]]; then
    resize_height=true
  fi
  if [[ "${width}" -lt "${min_width}" ]]; then
    resize_width=true
  fi
  # debug_log "file" "check active pane: height - current: ${height} = min: ${min_height}"
  # debug_log "file" "check active pane: width - current: ${width} = min: ${min_width}"
  echo -n "${id}-${resize_height}-${resize_width}-${top}-${bottom}-${left}-${right}"
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
  debug_log "file" "Check Active Pane: Height - current: ${active_height} = min: ${min_active_height}"
  debug_log "file" "Check Active Pane: Width - current: ${active_width} = min: ${min_active_width}"
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

# Get a tmux option value
#
# checks local setting and if unset checks and then sets global (-g) for inital default setting set
# in `.tmux.conf`.
#
# Parameter(s):
# - option (string): name of tmux option to get
#
# Return(s):
# - option_val (string): value of tmux setting
get_tmux_option() {
  local option="${1}"
  local default_value="${2}"

  read -r option_value< <(tmux show-options -qv "${option}")
  if [[ -z "${option_value}" ]]; then
    # Try global (-g)
    read -r option_value< <(tmux show-options -gqv "${option}")
    if [[ -z "${ACTIVE_PERCENTAGE}" ]]; then
      local option_value="${default_value}"
    fi
  fi

  set_tmux_option "${option}" "${option_value}"

  echo "${option_value}"
}

# Set a tmux option value locally
#
# Parameter(s):
# - option (string): name of tmux option to set
# - option_value (string): value of tmux option to set
set_tmux_option() {
  local option="${1}"
  local option_value="${2}"
  tmux set-option "${option}" "${option_value}"
}
