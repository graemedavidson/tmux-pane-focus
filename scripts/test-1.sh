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

# echo ":resize required (${active_percentage}%) | h:${resize_height} (active:${active_height} min:${active_min_height}) | w:${resize_width} (active:${active_width}, min:${active_min_width}) | window h:${window_height} x w:${window_width}"
tmux display-message ":resize required (${active_percentage}%) | h:${resize_height} (active:${active_height}, min:${active_min_height}) | w:${resize_width} (active:${active_width}, min:${active_min_width}) | window h:${window_height} x w:${window_width}"

panes=$(tmux list-panes -F "#{pane_index}-#{pane_left}-#{pane_top}-#{pane_right}-#{pane_bottom}-#{pane_active}" | sort -n)

if [[ "${resize_height}" == "true" ]] && [[ "${resize_height_setting}" == "true" ]]; then
  resize_height_panes=()
  declare -A inactive_height_parent_panes
  parents=()
  prev_top=0
  prev_bottom=0
  prev_left=0
  prev_index=0
  if [[ "${resize_height}" == "true" ]]; then
    for pane in ${panes}; do
      IFS=- read -r index left top right bottom _< <(echo "${pane}")

      # printf "i:%d - L:%d\tR:%d\tT:%d\tB:%d\n" "${index}" "${left}" "${right}" "${top}" "${bottom}"

      inactive_height_parent_panes+=( ["${index}"]=0 )

      read -r in_column< <(in_col_row "${left}" "${active_left}" "${right}" "${active_right}")
      if [[ "${in_column}" == "false" ]]; then
        continue
      fi
      resize_height_panes+=("${index}")

      if [[ "${left}" -eq "${prev_top}" ]] && [[ "${bottom}" -eq "${prev_bottom}" ]]; then
        unset "resize_height_panes[-1]"
      elif [[ "${top}" -ge "${prev_top}" ]] && [[ "${bottom}" -le "${prev_bottom}" ]]; then
        if [[ "${left}" -gt "${prev_left}" ]]; then
          parents+=("${prev_index}")
        elif [[ "${left}" -lt "${prev_left}" ]]; then
          # echo "unset"
          unset 'parents[-1]'
        fi
        # echo "${parents[@]}"
        # echo "current index: ${parents[-1]}"
        ((inactive_width_parent_panes["${parents[-1]}"]=inactive_width_parent_panes["${parents[-1]}"]+1))
      else
        prev_top="${top}"
        prev_bottom="${bottom}"
      fi
      prev_top="${top}"
      prev_index="${index}"
    done
  fi
fi

if [[ "${resize_width}" == "true" ]] && [[ "${resize_width_setting}" == "true" ]]; then
  resize_width_panes=()
  declare -A inactive_width_parent_panes
  parents=()
  prev_left=0
  prev_right=0
  prev_top=0
  prev_index=0

  if [[ "${resize_width}" == "true" ]]; then
    for pane in ${panes}; do
      IFS=- read -r index left top right bottom _< <(echo "${pane}")

      # printf "i:%d - L:%d\tR:%d\tT:%d\tB:%d\n" "${index}" "${left}" "${right}" "${top}" "${bottom}"

      inactive_width_parent_panes+=( ["${index}"]=0 )

      read -r in_row< <(in_col_row "${top}" "${active_top}" "${bottom}" "${active_bottom}")
      if [[ "${in_row}" == "false" ]]; then
        continue
      fi
      resize_width_panes+=("${index}")

      if [[ "${left}" -eq "${prev_left}" ]] && [[ "${right}" -eq "${prev_right}" ]]; then
        unset "resize_width_panes[-1]"
      elif [[ "${left}" -ge "${prev_left}" ]] && [[ "${right}" -le "${prev_right}" ]]; then
        if [[ "${top}" -gt "${prev_top}" ]]; then
          parents+=("${prev_index}")
        elif [[ "${top}" -lt "${prev_top}" ]]; then
          # echo "unset"
          unset 'parents[-1]'
        fi
        # echo "${parents[@]}"
        # echo "current index: ${parents[-1]}"
        ((inactive_width_parent_panes["${parents[-1]}"]=inactive_width_parent_panes["${parents[-1]}"]+1))
      else
        prev_left="${left}"
        prev_right="${right}"
      fi
      prev_top="${top}"
      prev_index="${index}"
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

# echo "resize height (horizontal) - inactive panes: ${inactive_height_panes}, parent panes: ${inactive_height_parent_pane_count}"
# echo "================="
# echo "${resize_height_panes[@]}"
# echo ""
# echo "resize width (vertical) - inactive panes: ${inactive_width_panes}, parent panes: ${inactive_width_parent_pane_count}"
# echo "================="
# echo "${resize_width_panes[@]}"
# echo ""
# echo "Inactive width parent panes:"
# echo "================="
# echo "${!inactive_width_parent_panes[@]}"
# echo "${inactive_width_parent_panes[@]}"
# echo ""

# Remove parent panes from count, remove -1 to account for 2 panes only having 1 split, remove parent pane count
if [[ "${inactive_height_panes}" -gt 1 ]]; then
  inactive_height_panes="$(( inactive_height_panes - inactive_height_parent_pane_count ))"
fi
if [[ "${inactive_width_panes}" -gt 1 ]]; then
  inactive_width_panes="$(( inactive_width_panes - inactive_width_parent_pane_count ))"
fi
# echo "inactive pane counts: ${inactive_height_panes} - ${inactive_width_panes}"

IFS=- read -r min_inactive_height< <(get_inactive_pane_size "${window_height}" "${active_percentage}" "${inactive_height_panes}")
IFS=- read -r min_inactive_width< <(get_inactive_pane_size "${window_width}" "${active_percentage}" "${inactive_width_panes}")
# echo "min inactives - height: ${min_inactive_height} - width: ${min_inactive_width}"

if [[ "${resize_height}" == "true" ]] && [[ "${resize_height_setting}" == "true" ]]; then
  # echo ""
  # echo "Resize height:"
  # echo "========================================="
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
    # echo "resize val: ${resize_value} (multiplier: ${inactive_height_parent_panes[${pane_index}]}) for ${pane_index}"
    resize_pane "${pane_index}" "${resize_value}" 0
  done
fi

if [[ "${resize_width}" == "true" ]] && [[ "${resize_width_setting}" == "true" ]]; then
  # echo ""
  # echo "Resize width:"
  # echo "========================================="
  for pane_index in "${resize_width_panes[@]}"; do
    if [[ "${pane_index}" -eq "${active_pane_index}" ]]; then
      resize_value="${active_min_width}"
    else
      if [[ "${inactive_width_parent_panes[${pane_index}]}" -gt 1 ]]; then
        resize_value=$(( min_inactive_width * inactive_width_parent_panes["${pane_index}"] ))
      else
        resize_value="${min_inactive_width}"
      fi
    fi
    # echo "resize val: ${resize_value} (multiplier: ${inactive_width_parent_panes[${pane_index}]}) for ${pane_index}"
    resize_pane "${pane_index}" 0 "${resize_value}"
  done
fi
