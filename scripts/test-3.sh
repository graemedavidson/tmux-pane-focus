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
IFS=- read -r active_pane_id resize_height resize_width active_min_height active_min_width active_top active_bottom active_left active_right active_height active_width< <(get_active_pane "${window_height}" "${window_width}" "${active_percentage}")

echo ":resize required - height: ${resize_height} (active: ${active_height}, min: ${active_min_height}), width: ${resize_width} (active: ${active_width}, min: ${active_min_width})"
tmux display-message ":resize required - height: ${resize_height} (active: ${active_height}, min: ${active_min_height}), width: ${resize_width} (active: ${active_width}, min: ${active_min_width})"

panes=$(tmux list-panes -F "#{pane_index}-#{pane_left}-#{pane_top}-#{pane_right}-#{pane_bottom}-#{pane_active}-#{pane_id}-#{pane_index}" | sort -n)

resize_height_panes=()
declare -A inactive_height_panes
prev_top=0
prev_bottom=0
prev_id_height=""
if [[ "${resize_height}" == "true" ]]; then
  for pane in ${panes}; do
    IFS=- read -r _ left top right bottom active id index< <(echo "${pane}")

    if [[ "${active}" -eq 1 ]]; then
      resize_height_panes+=("${id}")
      prev_top="${top}"
      prev_bottom="${bottom}"
      prev_id_height="${id}"
      continue
    fi

    # Do not add a pane if a previous pane with same sides has been added
    inactive_height_panes+=( ["${id}"]=0 )
    # echo "if [[ ${top} -le ${prev_top} ]] && [[ ${bottom} -ge ${prev_bottom} ]] && [[ ${prev_id_height} != ${active_pane_id} ]]; then"
    if [[ "${top}" -le "${prev_top}" ]] && [[ "${bottom}" -ge "${prev_bottom}" ]] && [[ "${prev_id_height}" != "${active_pane_id}" ]]; then
      # echo "true (htp): ${prev_id_height}"
      ((inactive_height_panes["${prev_id_height}"]=inactive_height_panes["${prev_id_height}"]+1))
    else
      prev_top="${top}"
      prev_bottom="${bottom}"
      prev_id_height="${id}"
    fi

    if [[ "${left}" -ge "${active_left}" ]] && [[ "${left}" -le "${active_right}" ]]; then
      resize_height_panes+=("${id}")
    elif [[ "${right}" -le "${active_right}" ]] && [[ "${right}" -ge "${active_left}" ]]; then
      resize_height_panes+=("${id}")
    elif [[ "${left}" -le "${active_left}" ]] && [[ "${right}" -ge "${active_right}" ]]; then
      resize_height_panes+=("${id}")
    fi
  done
fi

resize_width_panes=()
declare -A inactive_width_panes
prev_left=0
prev_right=0
prev_id_width=""
if [[ "${resize_width}" == "true" ]]; then
  for pane in ${panes}; do
    IFS=- read -r _ left top right bottom active id index< <(echo "${pane}")

    # echo "previous: L:${prev_left} R:${prev_right} ID:${prev_id_width}"
    if [[ "${active}" -eq 1 ]]; then
      resize_width_panes+=("${id}")

      if [[ "${left}" -ge "${prev_left}" ]] && [[ "${right}" -le "${prev_right}" ]]; then
        unset 'inactive_width_panes[${prev_id_width}]'
        prev_left="${right}"
        prev_right=$(( right + 1 ))
        prev_id_width="${id}"
      else
        prev_left="${left}"
        prev_right="${right}"
        prev_id_width="${id}"
      fi

      continue
    fi

    inactive_width_panes+=( ["${id}"]=0 )
    # echo "${index}: if L:[[ '${left}' -ge '${prev_left}' ]] && R:[[ '${right}' -le '${prev_right}' ]]; then"
    if [[ "${left}" -ge "${prev_left}" ]] && [[ "${right}" -le "${prev_right}" ]]; then
      # echo "true (wlr): ${prev_id_width}"
      ((inactive_width_panes["${prev_id_width}"]=inactive_width_panes["${prev_id_width}"]+1))
    else
      prev_left="${left}"
      prev_right="${right}"
      prev_id_width="${id}"
    fi

    # echo "new: L:${prev_left} R:${prev_right} ID:${prev_id_width}"
    # echo "============"

    if [[ "${top}" -ge "${active_top}" ]] && [[ "${top}" -le "${active_bottom}" ]]; then
      resize_width_panes+=("${id}")
    elif [[ "${bottom}" -le "${active_bottom}" ]] && [[ "${bottom}" -ge "${active_top}" ]]; then
      resize_width_panes+=("${id}")
    elif [[ "${top}" -le "${active_top}" ]] && [[ "${bottom}" -ge "${active_bottom}" ]]; then
      resize_width_panes+=("${id}")
    fi
  done
fi

# Remove active pane and parent panes from count
parent_height_panes=0
parent_width_panes=0
for pane_id in "${!inactive_height_panes[@]}"; do
  if [[ "${inactive_height_panes[${pane_id}]}" -gt 1 ]]; then
    ((parent_height_panes=parent_height_panes+1))
  fi
done
for pane_id in "${!inactive_width_panes[@]}"; do
  if [[ "${inactive_width_panes[${pane_id}]}" -gt 1 ]]; then
    ((parent_width_panes=parent_width_panes+1))
  fi
done

# Remove actie pane from count
inactive_height_panes="$(( ${#resize_height_panes[@]} - 1))"
inactive_width_panes="$(( ${#resize_width_panes[@]} - 1))"

echo ""
echo "Active Percentage: ${active_percentage}"
echo "window height: ${window_height} x width: ${window_width}"
echo ""
echo "resize height (horizontal) - inactive panes: ${inactive_height_panes}, parent panes: ${parent_height_panes}"
echo "================="
echo "${resize_height_panes[@]}"
echo ""
echo "resize width (vertical) - inactive panes: ${inactive_width_panes}, parent panes: ${parent_width_panes}"
echo "================="
echo "${resize_width_panes[@]}"
echo ""

# Remove parent panes from count
inactive_height_panes="$(( inactive_height_panes - parent_height_panes))"
inactive_width_panes="$(( inactive_width_panes - parent_width_panes))"

IFS=- read -r min_inactive_height< <(get_inactive_pane_size "${window_height}" "${active_percentage}" "${inactive_height_panes}")
IFS=- read -r min_inactive_width< <(get_inactive_pane_size "${window_width}" "${active_percentage}" "${inactive_width_panes}")
echo "min inactives - height: ${min_inactive_height} - width: ${min_inactive_width}"

if [[ "${resize_height}" == "true" ]] && [[ "${resize_height_setting}" == "true" ]]; then
  for pane_id in "${resize_height_panes[@]}"; do
    if [[ "${pane_id}" == "${active_pane_id}" ]]; then
      resize_value="${active_min_height}"
    else
      if [[ "${inactive_height_panes[${pane_id}]}" -gt 1 ]]; then
        resize_value=$(( min_inactive_height * inactive_height_panes[${pane_id}] ))
      else
        resize_value="${min_inactive_height}"
      fi
    fi
    echo "resize height val: ${resize_value} (multiplier: ${inactive_height_panes[${pane_id}]}) for ${pane_id}"
    resize_pane "${pane_id}" "${resize_value}" 0
    # sleep 0.5
  done
fi

if [[ "${resize_width}" == "true" ]] && [[ "${resize_width_setting}" == "true" ]]; then
  for pane_id in "${resize_width_panes[@]}"; do
    if [[ "${pane_id}" == "${active_pane_id}" ]]; then
      resize_value="${active_min_width}"
    else
      if [[ "${inactive_width_panes[${pane_id}]}" -gt 1 ]]; then
        resize_value=$(( min_inactive_width * inactive_width_panes[${pane_id}] ))
      else
        resize_value="${min_inactive_width}"
      fi
    fi
    echo "resize width val: ${resize_value} (multiplier: ${inactive_width_panes[${pane_id}]}) for ${pane_id}"
    resize_pane "${pane_id}" 0 "${resize_value}"
    # sleep 0.5
  done
fi
