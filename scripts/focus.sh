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
IFS=- read -r active_pane_index resize_height resize_width active_min_height active_min_width active_top active_bottom active_left active_right active_height active_width< <(get_active_pane "${window_height}" "${window_width}" "${active_percentage}")

echo ":resize required - height: ${resize_height} (active: ${active_height}, min: ${active_min_height}), width: ${resize_width} (active: ${active_width}, min: ${active_min_width})"
tmux display-message ":resize required - height: ${resize_height} (active: ${active_height}, min: ${active_min_height}), width: ${resize_width} (active: ${active_width}, min: ${active_min_width})"

panes=$(tmux list-panes -F "#{pane_index}-#{pane_left}-#{pane_top}-#{pane_right}-#{pane_bottom}-#{pane_active}" | sort -n)

if [[ "${resize_height}" == "true" ]] && [[ "${resize_height_setting}" == "true" ]]; then
  resize_height_panes=()
  declare -A inactive_height_parent_panes
  prev_top=0
  prev_bottom=0
  prev_i_height=0
  left_marker=-1
  if [[ "${resize_height}" == "true" ]]; then
    for pane in ${panes}; do
      IFS=- read -r index left top right bottom active< <(echo "${pane}")

      if [[ "${active}" -eq 1 ]]; then
        resize_height_panes+=("${index}")
        continue
      fi

      inactive_height_parent_panes+=( ["${index}"]=0 )

      # echo "if [[ '${top}' -eq '${prev_top}' ]] && [[ '${bottom}' -eq '${prev_bottom}' ]]; then"
      echo "elif [[ '${top}' -ge '${prev_top}' ]] && [[ '${bottom}' -le '${prev_bottom}' ]]; then"
      if [[ "${top}" -eq "${prev_top}" ]] && [[ "${bottom}" -eq "${prev_bottom}" ]]; then
        echo "< ---- continue"
        # Do not add pane if full height child, as parent change handles.
        continue
      elif [[ "${top}" -ge "${prev_top}" ]] && [[ "${bottom}" -le "${prev_bottom}" ]]; then
        if [[ "${left_marker}" -eq -1 ]]; then
          left_marker="${left}"
        fi
        ((inactive_height_parent_panes["${prev_i_height}"]=inactive_height_parent_panes["${prev_i_height}"]+1))
        echo "parent: ${prev_i_height} - child true: ${index} - set left marker ${left_marker}"
      else
        prev_top="${top}"
        prev_bottom="${bottom}"
        prev_i_height="${index}"
        left_marker=-1
      fi

      if [[ "${left}" -ge "${active_left}" ]] && [[ "${left}" -le "${active_right}" ]]; then
        resize_height_panes+=("${index}")
      elif [[ "${right}" -le "${active_right}" ]] && [[ "${right}" -ge "${active_left}" ]]; then
        resize_height_panes+=("${index}")
      elif [[ "${left}" -le "${active_left}" ]] && [[ "${right}" -ge "${active_right}" ]]; then
        resize_height_panes+=("${index}")
      fi
    done
  fi
fi

if [[ "${resize_width}" == "true" ]] && [[ "${resize_width_setting}" == "true" ]]; then
  resize_width_panes=()
  declare -A inactive_width_parent_panes
  prev_left=0
  prev_right=0
  prev_i_width=0
  top_marker=-1
  if [[ "${resize_width}" == "true" ]]; then
    for pane in ${panes}; do
      IFS=- read -r index left top right bottom active< <(echo "${pane}")

      if [[ "${active}" -eq 1 ]]; then
        resize_width_panes+=("${index}")
        continue
      fi

      inactive_width_parent_panes+=( ["${index}"]=0 )

      echo "if [[ '${left}' -ge '${prev_left}' ]] && [[ '${right}' -le '${prev_right}' ]] && [[ '${top_marker}' -eq -1 or ${top} ]]; then"
      if [[ "${left}" -eq "${prev_left}" ]] && [[ "${right}" -eq "${prev_right}" ]]; then
        # Do not add pane if full width child, as parent change handles.
        continue
      elif [[ "${left}" -ge "${prev_left}" ]] && [[ "${right}" -le "${prev_right}" ]]; then
        if [[ "${top_marker}" -eq -1 ]]; then
          top_marker="${top}"
        fi
        ((inactive_width_parent_panes["${prev_i_width}"]=inactive_width_parent_panes["${prev_i_width}"]+1))
        echo "parent: ${prev_i_width} - child true: ${index} - set top marker ${top_marker}"
      else
        prev_left="${left}"
        prev_right="${right}"
        prev_i_width="${index}"
        top_marker=-1
      fi

      if [[ "${top}" -ge "${active_top}" ]] && [[ "${top}" -le "${active_bottom}" ]]; then
        resize_width_panes+=("${index}")
      elif [[ "${bottom}" -le "${active_bottom}" ]] && [[ "${bottom}" -ge "${active_top}" ]]; then
        resize_width_panes+=("${index}")
      elif [[ "${top}" -le "${active_top}" ]] && [[ "${bottom}" -ge "${active_bottom}" ]]; then
        resize_width_panes+=("${index}")
      fi
    done
  fi
fi

# Count of parent panes
inactive_height_parent_pane_count=0
inactive_width_parent_pane_count=0
for pane_index in "${!inactive_height_parent_panes[@]}"; do
  if [[ "${inactive_height_parent_panes[${pane_index}]}" -gt 0 ]]; then
    ((inactive_height_parent_pane_count=inactive_height_parent_pane_count+1))
  fi
done
for pane_index in "${!inactive_width_parent_panes[@]}"; do
  if [[ "${inactive_width_parent_panes[${pane_index}]}" -gt 0 ]]; then
    ((inactive_width_parent_pane_count=inactive_width_parent_pane_count+1))
  fi
done

# Remove active pane from count
inactive_height_panes="$(( ${#resize_height_panes[@]} - 1))"
inactive_width_panes="$(( ${#resize_width_panes[@]} - 1))"

echo ""
echo "Active Percentage: ${active_percentage}"
echo "window height: ${window_height} x width: ${window_width}"
echo ""
echo "resize height (horizontal) - inactive panes: ${inactive_height_panes}, parent panes: ${inactive_height_parent_pane_count}"
echo "================="
echo "${resize_height_panes[@]}"
echo ""
echo "resize width (vertical) - inactive panes: ${inactive_width_panes}, parent panes: ${inactive_width_parent_pane_count}"
echo "================="
echo "${resize_width_panes[@]}"
echo ""

# Remove parent panes from count, remove -1 to account for 2 panes only having 1 split, remove parent pane count
inactive_height_panes="$(( inactive_height_panes - inactive_height_parent_pane_count))"
inactive_width_panes="$(( inactive_width_panes - inactive_width_parent_pane_count))"
echo "inactive pane counts: ${inactive_height_panes} - ${inactive_width_panes}"

IFS=- read -r min_inactive_height< <(get_inactive_pane_size "${window_height}" "${active_percentage}" "${inactive_height_panes}")
IFS=- read -r min_inactive_width< <(get_inactive_pane_size "${window_width}" "${active_percentage}" "${inactive_width_panes}")
echo "min inactives - height: ${min_inactive_height} - width: ${min_inactive_width}"

if [[ "${resize_height}" == "true" ]] && [[ "${resize_height_setting}" == "true" ]]; then
  for pane_index in "${resize_height_panes[@]}"; do
    if [[ "${pane_index}" -eq "${active_pane_index}" ]]; then
      resize_value="${active_min_height}"
    else
      if [[ "${inactive_height_parent_panes[${pane_index}]}" -gt 1 ]]; then
        resize_value=$(( min_inactive_height * inactive_height_parent_panes[${pane_index}] ))
      else
        resize_value="${min_inactive_height}"
      fi
    fi
    echo "resize height val: ${resize_value} (multiplier: ${inactive_height_parent_panes[${pane_index}]}) for ${pane_index}"
    resize_pane "${pane_index}" "${resize_value}" 0
  done
fi

if [[ "${resize_width}" == "true" ]] && [[ "${resize_width_setting}" == "true" ]]; then
  for pane_index in "${resize_width_panes[@]}"; do
    if [[ "${pane_index}" -eq "${active_pane_index}" ]]; then
      resize_value="${active_min_width}"
    else
      if [[ "${inactive_width_parent_panes[${pane_index}]}" -gt 1 ]]; then
        resize_value=$(( min_inactive_width * inactive_width_parent_panes[${pane_index}] ))
      else
        resize_value="${min_inactive_width}"
      fi
    fi
    echo "resize width val: ${resize_value} (multiplier: ${inactive_width_parent_panes[${pane_index}]}) for ${pane_index}"
    resize_pane "${pane_index}" 0 "${resize_value}"
  done
fi
