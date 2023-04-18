#!/usr/bin/env bash

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Not working: shellcheck source=./scripts/functions.sh
# shellcheck source=/dev/null
. "${current_dir}/functions-2.sh"

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
IFS=- read -r active_pane_id resize_height resize_width active_min_height active_min_width active_top active_bottom active_left active_right< <(get_active_pane "${window_height}" "${window_width}" "${active_percentage}")

echo "resize required - height: ${resize_height}, width: ${resize_width}"
tmux display-message ":resize required - height: ${resize_height}, width: ${resize_width}"

resize_height_panes=()
if [[ "${resize_height_setting}" == "true" ]] && [[ "${resize_height}" == "true" ]]; then
  horizontal_panes=$(tmux list-panes -F "#{pane_bottom}-#{pane_left}-#{pane_right}-#{pane_active}-#{pane_id}-#{pane_height}" | sort -n)

  for pane in ${horizontal_panes}; do
    IFS=- read -r bottom left right active id _ < <(echo "${pane}")

    if [[ "${active}" -eq 1 ]]; then
      resize_height_panes+=("${id}")
    elif [[ "${left}" -ge "${active_left}" ]] && [[ "${left}" -le "${active_right}" ]]; then
      resize_height_panes+=("${id}")
    elif [[ "${right}" -le "${active_right}" ]] && [[ "${right}" -ge "${active_left}" ]]; then
      resize_height_panes+=("${id}")
    elif [[ "${left}" -le "${active_left}" ]] && [[ "${right}" -ge "${active_right}" ]]; then
      resize_height_panes+=("${id}")
    fi
  done
fi

resize_width_panes=()
if [[ "${resize_width_setting}" == "true" ]] && [[ "${resize_width}" == "true" ]]; then
  vertical_panes=$(tmux list-panes -F "#{pane_right}-#{pane_top}-#{pane_bottom}-#{pane_active}-#{pane_id}-#{pane_width}" | sort -n)

  for pane in ${vertical_panes}; do
    IFS=- read -r right top bottom active id _ < <(echo "${pane}")

    if [[ "${active}" -eq 1 ]]; then
      resize_width_panes+=("${id}")
    elif [[ "${top}" -ge "${active_top}" ]] && [[ "${top}" -le "${active_bottom}" ]]; then
      resize_width_panes+=("${id}")
    elif [[ "${bottom}" -le "${active_bottom}" ]] && [[ "${bottom}" -ge "${active_top}" ]]; then
      resize_width_panes+=("${id}")
    elif [[ "${top}" -le "${active_top}" ]] && [[ "${bottom}" -ge "${active_bottom}" ]]; then
      resize_width_panes+=("${id}")
    fi
  done
fi

echo "Active Percentage: ${active_percentage}"
echo ""
echo "resize height (horizontal) panes [$(( ${#resize_height_panes[@]} -1 ))]:"
echo "================="
echo "${resize_height_panes[@]}"
echo ""
echo "resize width (vertical) panes [$(( ${#resize_width_panes[@]} -1 ))]:"
echo "================="
echo "${resize_width_panes[@]}"
echo ""

# Remove 1 from passed panes to account for active pane
IFS=- read -r min_inactive_height< <(get_inactive_pane_size "${window_height}" "${active_percentage}" "$(( ${#resize_height_panes[@]} -1 ))")
IFS=- read -r min_inactive_width< <(get_inactive_pane_size "${window_width}" "${active_percentage}" "$(( ${#resize_width_panes[@]} -1 ))")

echo "min inactives - height: ${min_inactive_height} - width: ${min_inactive_width}"
echo ""
echo "^^^^^^^^^^^^^^^^^^^^"

for pane_id in "${resize_height_panes[@]}"; do
  if [[ "${pane_id}" == "${active_pane_id}" ]]; then
    resize_pane "${pane_id}" "${active_min_height}" 0
    echo "resize_pane height active - id: ${pane_id} - ${active_min_height} 0"
  else
    resize_pane "${pane_id}" "${min_inactive_height}" 0
    echo "resize_pane height - id: ${pane_id} - ${min_inactive_height} 0"
  fi
done

for pane_id in "${resize_width_panes[@]}"; do
  if [[ "${pane_id}" == "${active_pane_id}" ]]; then
    resize_pane "${pane_id}" 0 "${active_min_width}"
    echo "resize_pane width active - id: ${pane_id} - 0 ${active_min_width}"
  else
    resize_pane "${pane_id}" 0 "${min_inactive_width}"
    echo "resize_pane width - id: ${pane_id} - 0 ${min_inactive_width}"
  fi
done
