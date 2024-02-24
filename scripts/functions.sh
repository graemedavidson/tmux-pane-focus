#!/usr/bin/env bash

# Check if the active pane requires resize
#
# Parameter(s):
# - window_height (integer): height of window
# - window_width (integer): width of window
# - active_percentage (integer): size in percentage required for active pane
#
# Return(s):
# - index (interger): index of active pane
# - resize_height (string): true|false value indicating if resize required
# - resize_width (string): true|false value indicating if resize required
# - min_height (interger): minimum size of active pane height
# - min_width (interger): minimum size of active pane width
# - top (interger): pane top value
# - bottom (interger): pane bottom value
# - left (interger): pane left value
# - right (interger): pane right value
get_active_pane() {
  local window_height="${1}"
  local window_width="${2}"
  local active_percentage="${3}"

  IFS=- read -r index height width top bottom left right< <(tmux list-panes -F "#{pane_index}-#{pane_height}-#{pane_width}-#{pane_top}-#{pane_bottom}-#{pane_left}-#{pane_right}" -f "#{m:1,#{pane_active}}")

  local min_height=$(((window_height * active_percentage / 100) - 1))
  local min_width=$(((window_width * active_percentage / 100) - 1))

  local resize_height=false
  local resize_width=false
  if [[ "${height}" -lt "${min_height}" ]]; then
    local resize_height=true
  fi
  if [[ "${width}" -lt "${min_width}" ]]; then
    local resize_width=true
  fi

  echo -n "${index}-${resize_height}-${resize_width}-${min_height}-${min_width}-${top}-${bottom}-${left}-${right}-${height}-${width}"
}

# Determine inactive pane size
#
# Parameter(s):
# - window_size (integer): height/width of window
# - active_percentage (integer): size in percentage required for active pane
# - number of inactive panes (integer): the number of inactive panes in row/col of active pane
#
# Return(s):
# - resize_size (string): min size of inactive pane
get_inactive_pane_size() {
  local window_size="${1}"
  local active_percentage="${2}"
  local num_panes="${3}"

  local inactive_percentage=$((100 - active_percentage))
  local min_inactive=$(((window_size * inactive_percentage / 100) / num_panes))
  echo "${min_inactive}"
}

# Resize a tmux pane by percentage
#
# Parameter(s):
# - pane_index (interger): unique id for tmux pane to be changed
# - pane_height (integer): height value to change pane to
# - pane_width (integer): width value to change pane to
resize_pane() {
  pane_index="${1}"
  pane_height="${2}"
  pane_width="${3}"

  if [[ ${pane_height} -gt 0 ]] && [[ ${pane_width} -gt 0 ]]; then
    tmux resize-pane -t "${pane_index}" -y "${pane_height}" -x "${pane_width}"
  elif [[ $pane_height -gt 0 ]]; then
    tmux resize-pane -t "${pane_index}" -y "${pane_height}"
  elif [[ $pane_width -gt 0 ]]; then
    tmux resize-pane -t "${pane_index}" -x "${pane_width}"
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

  read -r option_value< <(tmux show-options -wqv "${option}")
  if [[ -z "${option_value}" ]]; then
    # Try global (-g)
    read -r option_value< <(tmux show-options -gqv "${option}")
  fi
  if [[ -z "${option_value}" ]]; then
    local option_value="${default_value}"
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
  tmux set-option -w "${option}" "${option_value}"
}

# Determine if inactive pane inside boundaries of active pane col or row
#
# Takes left and right values for determining column or top and bottom for row.
#
# Parameter(s):
# - side_a (integer): value of side of inactive pane
# - side_a_active (integer): value of side of active pane for comparison
# - side_b (integer): value of side of inactive pane
# - side_b_active (integer): value of side of active pane for comparison
#
# Return(s):
# - result (bool): true if inactive pane within boundaries of active pane, else false
in_col_row() {
  local side_a="${1}"
  local side_a_active="${2}"
  local side_b="${3}"
  local side_b_active="${4}"

  local result=false

  if [[ "${side_a}" -ge "${side_a_active}" ]] && [[ "${side_a}" -le "${side_b_active}" ]]; then
    local result=true
  elif [[ "${side_b}" -le "${side_b_active}" ]] && [[ "${side_b}" -ge "${side_a_active}" ]]; then
    local result=true
  elif [[ "${side_a}" -le "${side_a_active}" ]] && [[ "${side_b}" -ge "${side_b_active}" ]]; then
    local result=true
  fi

  echo "${result}"
}

# Get count of inactive parent panes (panes with children)
#
# Returns a count of inactive parent panes (panes with children) that are not in the col/row of focused pane that also have child panes.
#
# Parameter(s):
# - panes (list): list of panes
#
# Return(s):
# - count (interger): Number of inactive parent panes.
get_inactive_parent_pane_count() {
  local panes=("$@")

  local count=0
  for pane_index in "${!panes[@]}"; do
    if [[ "${panes[${pane_index}]}" -gt 0 ]]; then
      ((count=count+1))
    fi
  done

  echo "${count}"
}

# Write to temporary debug log file
#
# Parameter(s):
# - messages (array): debug lines
#
write_debug_line() {
  local messages=("$@")

  for message in "${messages[@]}"; do
    echo -e "${message}" >> /tmp/tmux-pane-focus.log
  done
}
