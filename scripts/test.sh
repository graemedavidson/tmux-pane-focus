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

echo "horizontal panes:"
echo "================="
echo "${horizontal_panes}"
echo "================="
echo "settings > split count: ${horizontal_split_count}"
echo "-----------------------------------------------------------"
echo "vertical panes:"
echo "================="
echo "${vertical_panes}"
echo "================="
echo "settings > split count: ${vertical_split_count}"
echo "settings > active percentage: ${active_percentage}"
echo "settings > direction: ${direction} (${resize_height_setting}, ${resize_width_setting})"
echo "-----------------------------------------------------------"


IFS=- read -r active_pane_width_percentage inactive_pane_shared_width_percentage min_active_width min_inactive_width< <(get_settings "${vertical_split_count}" "${window_width}" "${active_percentage}")
IFS=- read -r active_pane_height_percentage inactive_pane_shared_height_percentage min_active_height min_inactive_height< <(get_settings "${horizontal_split_count}" "${window_height}" "${active_percentage}")

IFS=- read -r height_resize_required width_resize_required active_top active_bottom active_left active_right< <(get_active_pane "${min_active_height}" "${min_active_width}")

echo "resize required - height: ${height_resize_required}, width: ${width_resize_required}"
echo "active position - top: ${active_top} bottom: ${active_bottom} | left: ${active_left} right: ${active_right}"
echo "-----------------------------------------------------------"

echo ">>>>>>>>>>>>>>>>> horizontal / height <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
if [[ "${resize_height_setting}" == "true" ]] && [[ "${height_resize_required}" == "true" ]]; then
  for pane in ${horizontal_panes}; do
    IFS=- read -r _ left right active id height < <(echo "${pane}")

    if [[ "${active}" -eq 0 ]]; then
      if [[ "${active_left}" -eq "${left}" ]] && [[ "${active_right}" -eq "${right}" ]]; then
        # echo "(${id}) t: ${top}, b: ${bottom} - active: ${active} - width: ${width}"
        resize_pane "${id}" "${min_inactive_height}" 0
      elif [[ "${min_inactive_height}" -ne "${height}" ]]; then
        resize_pane "${id}" "${min_inactive_height}" 0
      fi
    else
      resize_pane "${id}" "${min_active_height}" 0
    fi
  done
fi


echo ">>>>>>>>>>>>>>>>> Vertical / Width <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
if [[ "${resize_width_setting}" == "true" ]] && [[ "${width_resize_required}" == "true" ]]; then
  for pane in ${vertical_panes}; do
    IFS=- read -r _ top bottom active id width < <(echo "${pane}")

    if [[ "${active}" -eq 0 ]]; then
      if [[ "${active_top}" -eq "${top}" ]] && [[ "${active_bottom}" -eq "${bottom}" ]]; then
        # echo "(${id}) t: ${top}, b: ${bottom} - active: ${active} - width: ${width}"
        resize_pane "${id}" 0 "${min_inactive_width}"
      elif [[ "${min_inactive_width}" -ne "${width}" ]]; then
        resize_pane "${id}" 0 "${min_inactive_width}"
      fi
    else
      echo "active"
      resize_pane "${id}" 0 "${min_active_width}"
    fi
  done
fi


exit 0



# Get horizontal/height panes - left to right (-)
# Get vertical/width panes - top to bottom (|)

# Get settings:
# - split counts
# - Active/Inactive percentages
# - Active/Inactive absolute values

# Determine if active pane requires resize and in which directions
# Determine which panes require resize (ignore those not affecting active pane)

