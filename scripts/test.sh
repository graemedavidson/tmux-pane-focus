#!/usr/bin/env bash

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Not working: shellcheck source=./scripts/functions.sh
# shellcheck source=/dev/null
. "${current_dir}/functions.sh"

pane_count=$(tmux list-panes | wc -l)
if [[ $pane_count -eq 1 ]]; then
  exit 0
fi

read -r active_percentage< <(get_tmux_option "@pane-focus-size" "50")
if [[ "${active_percentage}" == "off" ]]; then
  exit
elif [[ "${active_percentage}" -lt 50 ]] || [[ "${active_percentage}" -ge 100 ]]; then
  tmux display-message "#[bg=red]Invalid @pane-focus-size setting in .tmux.conf file: ${active_percentage}; expected value between 50 and 100.#[bg=default]"
  exit
fi

# Check session and then global (default in .tmux.conf), set session
read -r direction< <(get_tmux_option "@pane-focus-direction" "+")
if [[ ! "${direction}" =~ (\+|\-|\|) ]]; then
  tmux display-message "#[bg=red]Invalid @pane-focus-direction setting in .tmux.conf file: ${direction}; expected value '+', '|', '-'.#[bg=default]"
  exit
fi

resize_height_setting=true
resize_width_setting=true
if [[ "${direction}" == "|" ]]; then
  resize_height_setting=false
fi
if [[ "${direction}" == "-" ]]; then
  resize_width_setting=false
fi

IFS=- read -r window_height window_width < <(tmux list-windows -F "#{window_height}-#{window_width}" -f "#{m:1,#{window_active}}")

horizontal_panes=$(tmux list-panes -F "#{pane_bottom}-#{pane_left}-#{pane_right}-#{pane_active}-#{pane_id}-#{pane_height}" | sort -n)
vertical_panes=$(tmux list-panes -F "#{pane_right}-#{pane_top}-#{pane_bottom}-#{pane_active}-#{pane_id}-#{pane_width}" | sort -n)

read -r vertical_split_count< <(get_split_count "${vertical_panes}")
read -r horizontal_split_count< <(get_split_count "${horizontal_panes}")

# echo "horizontal panes:"
# echo "================="
# echo "${horizontal_panes}"
# echo "================="
# echo "settings > split count: ${horizontal_split_count}"
# echo "-----------------------------------------------------------"
# echo "vertical panes:"
# echo "================="
# echo "${vertical_panes}"
# echo "================="
# echo "settings > split count: ${vertical_split_count}"
# echo "settings > active percentage: ${active_percentage}"
# echo "settings > direction: ${direction} (${resize_height_setting}, ${resize_width_setting})"
# echo "-----------------------------------------------------------"
# exit

IFS=- read -r active_pane_width_percentage inactive_pane_shared_width_percentage min_active_width min_inactive_width< <(get_settings "${vertical_split_count}" "${window_width}" "${active_percentage}")
IFS=- read -r active_pane_height_percentage inactive_pane_shared_height_percentage min_active_height min_inactive_height< <(get_settings "${horizontal_split_count}" "${window_height}" "${active_percentage}")

IFS=- read -r height_resize_required width_resize_required active_top active_bottom active_left active_right< <(get_active_pane "${min_active_height}" "${min_active_width}")

# echo "resize required - height: ${height_resize_required}, width: ${width_resize_required}"
# echo "active position - top: ${active_top} bottom: ${active_bottom} | left: ${active_left} right: ${active_right}"
# echo "-----------------------------------------------------------"

# exit 0
#
tmux display-message ":resize required - height: ${height_resize_required}, width: ${width_resize_required}"

# echo ">>>>>>>>>>>>>>>>> horizontal / height <<<<<<<<<<<<<<<<<<<<<<<<<<<<"

resize_height_panes=()
if [[ "${resize_height_setting}" == "true" ]] && [[ "${height_resize_required}" == "true" ]]; then
  for pane in ${horizontal_panes}; do
    IFS=- read -r bottom left right active id height < <(echo "${pane}")

    if [[ "${active}" -eq 1 ]]; then
      # tmux send-keys -t "${id}" "updating height for active"
      resize_pane "${id}" "${min_active_height}" 0
      # sleep 2
      # tmux send-keys -R -t "${id}" C-l C-c
      resize_height_panes+=("${id}")
      continue
    fi

    if [[ "${bottom}" -ne "${active_bottom}" ]] && [[ "${height}" -gt "${min_inactive_height}" ]]; then
      resize_height_panes+=("${id}")
      resize_pane "${id}" "${min_inactive_height}" 0
    elif [[ "${left}" -le "${active_left}" ]] && [[ "${right}" -ge "${active_right}" ]] && [[ "${height}" -gt "${min_inactive_height}" ]]; then
      # echo "${id}: ${left} -le ${active_left} && ${right} -ge ${active_right} && ${height} -gt ${min_inactive_height}"
      resize_height_panes+=("${id}")
      # tmux send-keys -t "${id}" "updating height for inactive due to being greater than min"
      resize_pane "${id}" "${min_inactive_height}" 0
      # sleep 2
    fi

    #   # echo "(${id}) l: ${left}, r: ${right} - active l: ${active_left}, active r: ${active_right}"
    #   # tmux send-keys -t "${id}" "updating height for inactive due to on same col"
    #   # resize_pane "${id}" "${min_inactive_height}" 0
    #   # sleep 2
    #   if [[ "${height}" -gt "${min_inactive_height}" ]]; then
    #     # echo "(${id}) t: ${top}, b: ${bottom} - active: ${active} - width: ${width}"
    #     # tmux send-keys -t "${id}" "updating height for inactive due to being greater than min"
    #     # resize_pane "${id}" "${min_inactive_height}" 0
    #     # sleep 2
    #   fi
    # fi

    # tmux send-keys -R -t "${id}" C-l C-c
  done
fi


# echo ">>>>>>>>>>>>>>>>> Vertical / Width <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
resize_width_panes=()
if [[ "${resize_width_setting}" == "true" ]] && [[ "${width_resize_required}" == "true" ]]; then
  for pane in ${vertical_panes}; do
    IFS=- read -r right top bottom active id width < <(echo "${pane}")

    if [[ "${active}" -eq 1 ]]; then
      # tmux send-keys -t "${id}" "updating width for active"
      resize_pane "${id}" 0 "${min_active_width}"
      # sleep 2
      # tmux send-keys -R -t "${id}" C-l C-c
      resize_width_panes+=("${id}")
      continue
    fi

    if [[ "${right}" -ne "${active_right}" ]] && [[ "${height}" -gt "${min_inactive_height}" ]]; then
      resize_height_panes+=("${id}")
      resize_pane "${id}" 0 "${min_inactive_width}"
    elif [[ "${active_top}" -le "${top}" ]] && [[ "${active_bottom}" -ge "${bottom}" ]] && [[ "${width}" -gt "${min_inactive_width}" ]]; then
      # echo "${id}: ${active_top} -le ${top} && ${active_bottom} -ge ${bottom} && ${width} -gt ${min_inactive_width}"
      resize_width_panes+=("${id}")
      # tmux send-keys -t "${id}" "updating width for inactive due to on same col"
      resize_pane "${id}" 0 "${min_inactive_width}"
      # sleep 2
      # echo "(${id}) t: ${top}, b: ${bottom} - active: ${active} - width: ${width}"
      # tmux send-keys -t "${id}" "updating width for inactive due to on same col"
      # resize_pane "${id}" 0 "${min_inactive_width}"
      # sleep 2
      # if [[ "${width}" -gt "${min_inactive_width}" ]]; then
      #   # echo "(${id}) t: ${top}, b: ${bottom} - active: ${active} - width: ${width}"
      #   tmux send-keys -t "${id}" "updating width for inactive due to being greater than min"
      #   resize_pane "${id}" 0 "${min_inactive_width}"
      #   sleep 2
      # fi
    fi

    # tmux send-keys -R -t "${id}" C-l C-c
  done
fi

echo "resize height (horizontal) panes:"
echo "================="
echo "${resize_height_panes[@]}"
echo "================="
echo "resize width (vertical) panes:"
echo "================="
echo "${resize_width_panes[@]}"
echo "================="


exit 0



# Get horizontal/height panes - left to right (-)
# Get vertical/width panes - top to bottom (|)

# Get settings:
# - split counts
# - Active/Inactive percentages
# - Active/Inactive absolute values

# Determine if active pane requires resize and in which directions
# Determine which panes require resize (ignore those not affecting active pane)

