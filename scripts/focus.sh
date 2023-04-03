#!/usr/bin/env bash

exit 0

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Not working: shellcheck source=./scripts/functions.sh
# shellcheck source=/dev/null
. "${CURRENT_DIR}/functions.sh"

PANE_COUNT=$(tmux list-panes | wc -l)
if [[ $PANE_COUNT -eq 1 ]]; then
  exit 0
fi

read -r ACTIVE_PERCENTAGE< <(get_tmux_option "@pane-focus-size" "50")
if [[ "${ACTIVE_PERCENTAGE}" == "off" ]]; then
  exit
elif [[ "${ACTIVE_PERCENTAGE}" -lt 50 ]] || [[ "${ACTIVE_PERCENTAGE}" -ge 100 ]]; then
  tmux display-message "#[bg=red]Invalid @pane-focus-size setting in .tmux.conf file: ${ACTIVE_PERCENTAGE}; expected value between 50 and 100.#[bg=default]"
  exit
fi

# Check session and then global (default in .tmux.conf), set session
read -r DIRECTION< <(get_tmux_option "@pane-focus-direction" "+")
if [[ ! "${DIRECTION}" =~ (\+|\-|\|) ]]; then
  tmux display-message "#[bg=red]Invalid @pane-focus-direction setting in .tmux.conf file: ${DIRECTION}; expected value '+', '|', '-'.#[bg=default]"
  exit
fi

resize_vertically=true
resize_horizontally=true
if [[ "${DIRECTION}" == "-" ]]; then
  resize_vertically=false
fi
if [[ "${DIRECTION}" == "|" ]]; then
  resize_horizontally=false
fi

IFS=- read -r WINDOW_HEIGHT WINDOW_WIDTH < <(tmux list-windows -F "#{window_height}-#{window_width}" -f "#{m:1,#{window_active}}")

read -r VERTICAL_SPLIT_COUNT< <(get_split_count "right")
read -r HORIZONTAL_SPLIT_COUNT< <(get_split_count "bottom")

IFS=- read -r ACTIVE_PANE_WIDTH_PERCENTAGE INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE MIN_ACTIVE_WIDTH MIN_INACTIVE_WIDTH< <(get_settings "${VERTICAL_SPLIT_COUNT}" "${WINDOW_WIDTH}" "${ACTIVE_PERCENTAGE}")
IFS=- read -r ACTIVE_PANE_HEIGHT_PERCENTAGE INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE MIN_ACTIVE_HEIGHT MIN_INACTIVE_HEIGHT< <(get_settings "${HORIZONTAL_SPLIT_COUNT}" "${WINDOW_HEIGHT}" "${ACTIVE_PERCENTAGE}")

IFS=- read -r resize_height resize_width< <(check_active_pane "${MIN_ACTIVE_HEIGHT}" "${MIN_ACTIVE_WIDTH}")
if [[ "${resize_height}" == "false" ]] && [[ "${resize_width}" == "false" ]]; then
    exit 0
fi

tmux display-message "resize horizontal: ${resize_height} - resize vertical: ${resize_width}"
sleep 1

debug_log "file" "Settings - Active Percentage: ${ACTIVE_PERCENTAGE} | Resize Direction: ${DIRECTION}"
debug_log "file" "horizontal splits (-): ${HORIZONTAL_SPLIT_COUNT}, vertical splits (|): ${VERTICAL_SPLIT_COUNT}"
debug_log "file" "default active pane: H:${ACTIVE_PANE_HEIGHT_PERCENTAGE}% x W:${ACTIVE_PANE_WIDTH_PERCENTAGE}%"
debug_log "file" "default inactive pane: H:${INACTIVE_PANE_SHARED_HEIGHT_PERCENTAGE}% x W:${INACTIVE_PANE_SHARED_WIDTH_PERCENTAGE}%"
debug_log "file" "Window dimensions: H:${WINDOW_HEIGHT} x W:${WINDOW_WIDTH}"
debug_log "file" "minimum active dimensions: H:${MIN_ACTIVE_HEIGHT} x W:${MIN_ACTIVE_WIDTH}"
debug_log "file" "minimum inactive dimensions (taking into account number of splits): H:${MIN_INACTIVE_HEIGHT} x W:${MIN_INACTIVE_WIDTH}"
debug_log "file" "Resize height: ${resize_height} | Resize width: ${resize_width}"
debug_log "file" "---------------------------------------------------------------------------------"

debug_log "file" ">>>>>>>>>>>>>>>>> horizontal / height <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
if [[ "${resize_horizontally}" == "true" ]] && [[ "${resize_height}" == "true" ]]; then
  horizontal_panes=$(tmux list-panes -F "#{pane_bottom}-#{pane_active}-#{pane_id}-#{pane_height}" | sort -n)
  for pane in ${horizontal_panes}; do
    IFS=- read -r _ active id height < <(echo "${pane}")
    if [[ "${active}" -eq 1 ]]; then
      resize_pane "${id}" "${MIN_ACTIVE_HEIGHT}" 0
      tmux send-keys -t "${id}" "updating: ${id} - active"
      debug_log "file" "id: ${id} - updating active: ${MIN_ACTIVE_HEIGHT} - ${height}"
    else
      # Get latest width to take into account other changes
      IFS=- read -r height< <(tmux list-panes -F "#{pane_height}" -f "#{m:${id},#{pane_id}}")
      if [[ "${MIN_INACTIVE_HEIGHT}" -ne "${height}" ]]; then
        resize_pane "${id}" "${MIN_INACTIVE_HEIGHT}" 0
        tmux send-keys -t "${id}" "updating: ${id} - inactive"
        debug_log "file" "id: ${id} - updating inactive - min: ${MIN_INACTIVE_HEIGHT} - current: ${height}"
      fi
    fi
    sleep 1
    tmux send-keys -R -t "${id}" C-c
  done
fi

debug_log "file" ">>>>>>>>>>>>>>>>> Vertical / Width <<<<<<<<<<<<<<<<<<<<<<<<<<<<"

if [[ "${resize_vertically}" == "true" ]] && [[ "${resize_width}" == "true" ]]; then
  vertical_panes=$(tmux list-panes -F "#{pane_right}-#{pane_active}-#{pane_id}-#{pane_width}" | sort -n)
  for pane in ${vertical_panes}; do
    IFS=- read -r _ active id width< <(echo "${pane}")
    if [[ "${active}" -eq 1 ]]; then
      resize_pane "${id}" 0 "${MIN_ACTIVE_WIDTH}"
      tmux send-keys -t "${id}" "updating: ${id} - active"
      debug_log "file" "id: ${id} - updating active - min: ${MIN_ACTIVE_WIDTH} - current: ${width}"
    else
      # Get latest width to take into account other changes
      IFS=- read -r width< <(tmux list-panes -F "#{pane_width}" -f "#{m:${id},#{pane_id}}")
      if [[ "${MIN_INACTIVE_WIDTH}" -ne "${width}" ]]; then
        resize_pane "${id}" 0 "${MIN_INACTIVE_WIDTH}"
        tmux send-keys -t "${id}" "updating: ${id} - inactive"
        debug_log "file" "id: ${id} - updating inactive - min: ${MIN_INACTIVE_WIDTH} - current: ${width}"
      fi
    fi
    sleep 1
    tmux send-keys -R -t "${id}" C-c
  done
fi

debug_log "file" "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
