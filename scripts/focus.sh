#!/usr/bin/env bash

readonly MIN_SIZE_PERCENTAGE=50
readonly MAX_SIZE_PERCENTAGE=100
readonly DEBUG_LOG_PATH="/tmp/tmux-pane-focus.log"

# Source helper functions
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=/dev/null
. "${current_dir}/functions.sh"

# Validate the configured active-pane size percentage, warning via tmux's
# message bar if it's outside the allowed range.
#
# Parameter(s):
# - size (integer): the @pane-focus-size value to validate
#
# Return(s):
# - exit status (integer): 0 if valid, 1 if out of range
validate_size_percentage() {
  local size=$1
  if [[ "${size}" -lt ${MIN_SIZE_PERCENTAGE} ]] || [[ "${size}" -ge ${MAX_SIZE_PERCENTAGE} ]]; then
    tmux display-message "#[bg=red]Invalid @pane-focus-size: ${size}; expected ${MIN_SIZE_PERCENTAGE}-${MAX_SIZE_PERCENTAGE}#[bg=default]"
    return 1
  fi
  return 0
}

# Validate the configured focus direction, warning via tmux's message bar
# if it's not one of the recognised symbols.
#
# Parameter(s):
# - direction (string): the @pane-focus-direction value to validate;
#   expected to be '+', '|', or '-'
#
# Return(s):
# - exit status (integer): 0 if valid, 1 invalid
validate_direction() {
  local direction=$1
  case "${direction}" in
    '+' | '|' | '-') return 0 ;;
    *)
      tmux display-message "#[bg=red]Invalid @pane-focus-direction: ${direction}; expected '+', '|', or '-'#[bg=default]"
      return 1
      ;;
  esac
}

# Validate a boolean-typed tmux option, warning via tmux's message bar if
# it isn't literally "true" or "false".
#
# Parameter(s):
# - value (string): the option value to validate
# - name (string): the option's name, used only in the warning message
#
# Return(s):
# - exit status (integer): 0 if valid, 1 invalid
validate_boolean() {
  local value=$1
  local name=$2
  if [[ ! "${value}" =~ ^(true|false)$ ]]; then
    tmux display-message "#[bg=red]Invalid ${name}: ${value}; expected 'true' or 'false'#[bg=default]"
    return 1
  fi
  return 0
}

# Decide whether a given dimension should be resized for the configured
# focus direction.
#
# Parameter(s):
# - direction (string): the @pane-focus-direction value ('+', '|', or '-')
# - dimension (string): the dimension being checked, "height" or "width"
#
# Return(s):
# - exit status (integer): 0 (true) if the dimension should be resized for
#   this direction, 1 (false) otherwise
should_resize_dimension() {
  local direction=$1
  local dimension=$2  # "height" or "width"

  case "${direction}" in
    "|") [[ "${dimension}" == "width" ]] ;;
    "-") [[ "${dimension}" == "height" ]] ;;
    "+") return 0 ;;
    *) return 1 ;;
  esac
}

# Work out which panes need resizing for one dimension (height or width),
# and which of those panes are "parents" that contain nested child panes
# in the cross dimension (e.g. a wide pane split further into rows).
#
# Walks the sorted pane list once, tracking the previous pane's bounds
# along the dimension being resized (primary_start/primary_end) and along
# the other dimension (prev_cross), to detect duplicate-position panes
# (skip) and nested panes (record a parent relationship instead).
#
# Parameter(s):
# - dimension (string): "height" or "width"; which dimension to analyse
# - panes (string): newline/space separated
#   "index-left-top-right-bottom-active" tuples for every pane
# - active_start (integer): active pane's left (width) or top (height)
#   edge, used to check alignment with the active pane
# - active_end (integer): active pane's right (width) or bottom (height)
#   edge, used to check alignment with the active pane
# - result_panes (nameref to array): populated with the indexes of every
#   pane that needs resizing for this dimension
# - result_parents (nameref to associative array): populated with, per
#   pane index, the count of nested child panes it contains (0 if none)
#
# Local variable(s):
# - prev_cross (integer): previous pane's position along the other,
#   cross dimension (left for height, top for width)
# - prev_index (integer): previous pane's index
# - parents (array): stack of pane indexes currently considered a
#   "parent" of the pane being examined, used to attribute nested panes
#   to the correct ancestor
# - pane (string): current pane's raw "index-left-top-right-bottom-active"
#   tuple, from iterating over panes
# - index, left, top, right, bottom (integer): current pane's fields,
#   parsed from pane (the trailing "active" field is discarded)
# - primary_start, primary_end (integer): current pane's start/end along
#   the resized dimension
# - cross_coord (integer): current pane's position along the cross
#   dimension
# - check_start, check_end (integer): current pane's edges along the
#   cross dimension, compared against active_start/active_end to check
#   whether it's in the same row/column as the active pane
# - in_alignment (string): "true"/"false" result of that alignment check
calculate_resize_panes() {
  local dimension=$1  # "height" or "width"
  local panes=$2
  local active_start=$3
  local active_end=$4

  local -n result_panes=$5
  local -n result_parents=$6

  local prev_primary=0
  local prev_secondary=0
  local prev_cross=0
  local prev_index=0
  local -a parents=()

  for pane in ${panes}; do
    IFS=- read -r index left top right bottom _ <<< "${pane}"
    result_parents["${index}"]=0

    # Determine coordinates based on dimension
    local primary_start primary_end cross_coord
    local check_start check_end

    if [[ "${dimension}" == "height" ]]; then
      primary_start="${top}"
      primary_end="${bottom}"
      cross_coord="${left}"
      check_start="${left}"
      check_end="${right}"
    else
      primary_start="${left}"
      primary_end="${right}"
      cross_coord="${top}"
      check_start="${top}"
      check_end="${bottom}"
    fi

    # Check if pane is in same column/row as active pane
    read -r in_alignment < <(in_col_row "${check_start}" "${active_start}" "${check_end}" "${active_end}")
    [[ "${in_alignment}" == "false" ]] && continue

    result_panes+=("${index}")

    # Handle duplicate positions
    if [[ "${primary_start}" -eq "${prev_primary}" ]] && [[ "${primary_end}" -eq "${prev_secondary}" ]]; then
      unset "result_panes[-1]"
      continue
    fi

    # Handle nested panes
    if [[ "${primary_start}" -ge "${prev_primary}" ]] && [[ "${primary_end}" -le "${prev_secondary}" ]]; then
      if [[ "${cross_coord}" -gt "${prev_cross}" ]]; then
        parents+=("${prev_index}")
      elif [[ "${cross_coord}" -lt "${prev_cross}" ]]; then
        unset 'parents[-1]'
      fi
      ((result_parents["${parents[-1]}"]=result_parents["${parents[-1]}"]+1))
    else
      prev_primary="${primary_start}"
      prev_secondary="${primary_end}"
    fi

    prev_cross="${cross_coord}"
    prev_index="${index}"
  done
}

# Work out how many inactive panes need a minimum size calculated for
# them in one dimension, excluding the active pane and, once there's more
# than one, any parent panes (a parent's size is derived from its
# children instead of being an independent inactive pane).
#
# Parameter(s):
# - total_panes (integer): number of panes queued for resize in this
#   dimension (from calculate_resize_panes' result_panes), active pane
#   included
# - parent_count (integer): number of those panes that are parents of
#   nested panes
#
# Return(s):
# - inactive (integer): count of inactive, non-parent panes in this
#   dimension
calculate_inactive_pane_count() {
  local total_panes=$1
  local parent_count=$2

  local inactive=$(( total_panes - 1 ))
  if [[ "${inactive}" -gt 1 ]]; then
    inactive=$(( inactive - parent_count ))
  fi
  echo "${inactive}"
}

# Queue a resize-pane command (via resize_pane) for every pane in one
# dimension: the active pane gets active_size, other panes get
# min_inactive_size (multiplied up for panes that are parents of
# multiple nested panes, so a parent stays large enough for its children).
#
# Parameter(s):
# - dimension (string): "height" or "width"; which dimension to resize
# - panes_ref (nameref to array): pane indexes to resize, from
#   calculate_resize_panes' result_panes
# - parents_ref (nameref to associative array): per pane index, count of
#   nested child panes it contains, from calculate_resize_panes'
#   result_parents
# - active_index (integer): index of the currently active pane
# - active_size (integer): size to resize the active pane to
# - min_inactive_size (integer): minimum size to resize an inactive,
#   non-parent pane to
# - debug (string): "true"/"false"; whether to write each resize to the
#   debug log
#
# Local variable(s):
# - height_arg, width_arg (integer): the height/width values passed to
#   resize_pane for the current pane; whichever doesn't match dimension
#   stays 0, meaning "don't change this dimension"
# - pane_index (integer): current pane's index, from iterating over
#   panes_ref
# - resize_value (integer): size the current pane should be resized to,
#   before being assigned to height_arg or width_arg
# - parent_count (integer): current (inactive) pane's nested child count,
#   looked up from parents_ref
resize_dimension_panes() {
  local dimension=$1
  local -n panes_ref=$2
  local -n parents_ref=$3
  local active_index=$4
  local active_size=$5
  local min_inactive_size=$6
  local debug=$7

  local height_arg=0
  local width_arg=0

  for pane_index in "${panes_ref[@]}"; do
    local resize_value

    if [[ "${pane_index}" -eq "${active_index}" ]]; then
      resize_value="${active_size}"
    else
      local parent_count="${parents_ref[${pane_index}]}"
      if [[ "${parent_count}" -gt 1 ]]; then
        resize_value=$(( min_inactive_size * parent_count ))
      else
        resize_value="${min_inactive_size}"
      fi
    fi

    if [[ "${dimension}" == "height" ]]; then
      height_arg="${resize_value}"
      width_arg=0
    else
      height_arg=0
      width_arg="${resize_value}"
    fi

    resize_pane "${pane_index}" "${height_arg}" "${width_arg}"

    if [[ "${debug}" == "true" ]]; then
      write_debug_line "\t- pane: ${pane_index} ${height_arg} ${width_arg}"
    fi
  done
}

# Announce that debug logging is enabled via tmux's message bar, and
# write the run's starting configuration to the debug log.
#
# Parameter(s):
# - active_percentage (integer): configured @pane-focus-size
# - direction (string): configured @pane-focus-direction
# - resize_height (string): "true"/"false"; whether height resizing is
#   enabled for this direction
# - resize_width (string): "true"/"false"; whether width resizing is
#   enabled for this direction
# - window_height (integer): tmux window height
# - window_width (integer): tmux window width
# - panes (string): raw pane list being processed this run
log_debug_header() {
  local active_percentage=$1
  local direction=$2
  local resize_height=$3
  local resize_width=$4
  local window_height=$5
  local window_width=$6
  local panes=$7

  tmux display-message "#[bg=yellow]Debug logging enabled (${DEBUG_LOG_PATH})#[bg=default]"
  write_debug_line \
    "-------------------------------------" \
    "active percentage: ${active_percentage}" \
    "resize height: ${resize_height}, resize width: ${resize_width}, direction: ${direction}" \
    "window height: ${window_height}, width: ${window_width}" \
    "panes: [${panes}]"
}

# Write the height/width pane-resize calculations for this run to the
# debug log.
#
# Parameter(s):
# - height_panes (nameref to array): pane indexes queued for height resize
# - height_parents (nameref to associative array): per pane index,
#   nested child pane count in the height dimension
# - height_parent_count (integer): number of parent panes in the height
#   dimension
# - height_count (integer): number of inactive, non-parent panes in the
#   height dimension
# - width_panes (nameref to array): pane indexes queued for width resize
# - width_parents (nameref to associative array): per pane index, nested
#   child pane count in the width dimension
# - width_parent_count (integer): number of parent panes in the width
#   dimension
# - width_count (integer): number of inactive, non-parent panes in the
#   width dimension
log_debug_calculations() {
  local -n height_panes=$1
  local -n height_parents=$2
  local height_parent_count=$3
  local height_count=$4
  local -n width_panes=$5
  local -n width_parents=$6
  local width_parent_count=$7
  local width_count=$8

  write_debug_line \
    "height:" \
    "\tresize_height_panes: ${height_panes[*]}" \
    "\tinactive_height_parent_panes: ${height_parents[*]}" \
    "\tinactive_height_parent_pane_count: ${height_parent_count}" \
    "\tinactive_height_panes (count): ${height_count}" \
    "width:" \
    "\tresize_width_panes: ${width_panes[*]}" \
    "\tinactive_width_parent_panes: ${width_parents[*]}" \
    "\tinactive_width_parent_pane_count: ${width_parent_count}" \
    "\tinactive_width_panes (count): ${width_count}" \
    "resize panes:"
}

# Entry point, run once per pane-select/split-window hook. Reads the
# plugin's configuration and the current window/pane layout, works out
# which panes need resizing in each dimension, queues those resizes via
# resize_pane, and flushes them to tmux as one batched invocation.
#
# Local variable(s):
# - pane_count (integer): total panes in the window, used only for the
#   single-pane early exit
# - enabled (string): "on"/"off"; @pane-focus-enabled
# - active_percentage (integer): @pane-focus-size
# - direction (string): @pane-focus-direction
# - debug (string): "true"/"false"; @pane-focus-debug-log
# - window_height, window_width (integer): tmux window dimensions
# - active_pane_index (integer): index of the currently active pane
# - resize_height, resize_width (string): "true"/"false"; whether the
#   active pane is currently smaller than its required minimum height/
#   width, from get_active_pane
# - active_min_height, active_min_width (integer): minimum height/width
#   the active pane should be resized to, from get_active_pane
# - active_top, active_bottom, active_left, active_right (integer): the
#   active pane's current edges, used to find other panes in its row/
#   column
# - panes (string): every pane's "index-left-top-right-bottom-active"
#   tuple, one per line, sorted by index
# - resize_height_enabled, resize_width_enabled (string): "true"/"false";
#   whether the configured direction permits resizing this dimension at
#   all, from should_resize_dimension
# - resize_height_panes, resize_width_panes (array): pane indexes queued
#   for resize in each dimension, populated by calculate_resize_panes
# - inactive_height_parent_panes, inactive_width_parent_panes
#   (associative array): per pane index, nested child pane count in each
#   dimension, populated by calculate_resize_panes
# - inactive_height_parent_count, inactive_width_parent_count (integer):
#   number of parent panes in each dimension
# - inactive_height_count, inactive_width_count (integer): number of
#   inactive, non-parent panes in each dimension
# - min_inactive_height, min_inactive_width (integer): minimum size an
#   inactive pane should be resized to in each dimension
main() {
  # Early exit if only one pane
  local pane_count
  pane_count=$(tmux list-panes | wc -l)
  [[ ${pane_count} -eq 1 ]] && exit 0

  # Load configuration
  local enabled active_percentage direction debug
  read -r enabled < <(get_tmux_option "@pane-focus-enabled" "on")
  [[ "${enabled}" == "off" ]] && exit 0

  read -r active_percentage < <(get_tmux_option "@pane-focus-size" "50")
  validate_size_percentage "${active_percentage}" || exit 1

  read -r direction < <(get_tmux_option "@pane-focus-direction" "+")
  validate_direction "${direction}" || exit 1

  read -r debug < <(get_tmux_option "@pane-focus-debug-log" "false")
  validate_boolean "${debug}" "@pane-focus-debug-log" || exit 1

  # Get window dimensions
  local window_height window_width
  IFS=- read -r window_height window_width < <(
    tmux list-windows -F "#{window_height}-#{window_width}" -f "#{m:1,#{window_active}}"
  )

  # Get active pane information
  local active_pane_index resize_height resize_width
  local active_min_height active_min_width
  local active_top active_bottom active_left active_right

  IFS=- read -r active_pane_index resize_height resize_width \
    active_min_height active_min_width \
    active_top active_bottom active_left active_right _ _ < <(
    get_active_pane "${window_height}" "${window_width}" "${active_percentage}"
  )

  # Get all panes
  local panes
  panes=$(tmux list-panes -F "#{pane_index}-#{pane_left}-#{pane_top}-#{pane_right}-#{pane_bottom}-#{pane_active}" | sort -n)

  # Determine which dimensions to resize
  local resize_height_enabled resize_width_enabled
  resize_height_enabled=$(should_resize_dimension "${direction}" "height" && echo "true" || echo "false")
  resize_width_enabled=$(should_resize_dimension "${direction}" "width" && echo "true" || echo "false")

  if [[ "${debug}" == "true" ]]; then
    log_debug_header "${active_percentage}" "${direction}" \
      "${resize_height_enabled}" "${resize_width_enabled}" \
      "${window_height}" "${window_width}" "${panes}"
  fi

  # Process height resizing
  local -a resize_height_panes=()
  local -A inactive_height_parent_panes=()

  if [[ "${resize_height}" == "true" ]] && [[ "${resize_height_enabled}" == "true" ]]; then
    calculate_resize_panes "height" "${panes}" "${active_left}" "${active_right}" \
      resize_height_panes inactive_height_parent_panes
  fi

  # Process width resizing
  local -a resize_width_panes=()
  local -A inactive_width_parent_panes=()

  if [[ "${resize_width}" == "true" ]] && [[ "${resize_width_enabled}" == "true" ]]; then
    calculate_resize_panes "width" "${panes}" "${active_top}" "${active_bottom}" \
      resize_width_panes inactive_width_parent_panes
  fi

  # Calculate inactive pane counts
  local inactive_height_parent_count inactive_width_parent_count
  read -r inactive_height_parent_count < <(get_inactive_parent_pane_count "${inactive_height_parent_panes[@]}")
  read -r inactive_width_parent_count < <(get_inactive_parent_pane_count "${inactive_width_parent_panes[@]}")

  local inactive_height_count inactive_width_count
  inactive_height_count=$(calculate_inactive_pane_count "${#resize_height_panes[@]}" "${inactive_height_parent_count}")
  inactive_width_count=$(calculate_inactive_pane_count "${#resize_width_panes[@]}" "${inactive_width_parent_count}")

  # Calculate minimum sizes for inactive panes
  local min_inactive_height min_inactive_width
  IFS=- read -r min_inactive_height < <(get_inactive_pane_size "${window_height}" "${active_percentage}" "${inactive_height_count}")
  IFS=- read -r min_inactive_width < <(get_inactive_pane_size "${window_width}" "${active_percentage}" "${inactive_width_count}")

  if [[ "${debug}" == "true" ]]; then
    log_debug_calculations \
      resize_height_panes inactive_height_parent_panes "${inactive_height_parent_count}" "${inactive_height_count}" \
      resize_width_panes inactive_width_parent_panes "${inactive_width_parent_count}" "${inactive_width_count}"
  fi

  # Perform resizing
  if [[ "${resize_height}" == "true" ]] && [[ "${resize_height_enabled}" == "true" ]]; then
    resize_dimension_panes "height" resize_height_panes inactive_height_parent_panes \
      "${active_pane_index}" "${active_min_height}" "${min_inactive_height}" "${debug}"
  fi

  if [[ "${resize_width}" == "true" ]] && [[ "${resize_width_enabled}" == "true" ]]; then
    resize_dimension_panes "width" resize_width_panes inactive_width_parent_panes \
      "${active_pane_index}" "${active_min_width}" "${min_inactive_width}" "${debug}"
  fi

  # resize_pane() only queues; apply every queued resize as one tmux
  # invocation so the client redraws once for the final layout.
  flush_resize_panes
}

# Guarded so shellspec can `Include` this file to test main() under mocks
# without it immediately running against the real tmux.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
