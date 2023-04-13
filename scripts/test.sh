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

IFS=- read -r active_pane_id height_resize_required width_resize_required active_top active_bottom active_left active_right< <(get_active_pane "${min_active_height}" "${min_active_width}")

echo "resize required - height: ${height_resize_required}, width: ${width_resize_required}"
tmux display-message ":resize required - height: ${height_resize_required}, width: ${width_resize_required}"







resize_height_panes=()
h_inactive_pane_count=-1
if [[ "${resize_height_setting}" == "true" ]] && [[ "${height_resize_required}" == "true" ]]; then
  for pane in ${horizontal_panes}; do
    IFS=- read -r bottom left right active id height < <(echo "${pane}")

    if [[ "${right}" -eq "${active_right}" ]]; then
      # Count splits on active row
      ((h_inactive_pane_count=h_inactive_pane_count+1))
    fi

    if [[ "${active}" -eq 1 ]]; then
      resize_height_panes+=("${id}")
      continue
    fi

    if [[ "${bottom}" -ne "${active_bottom}" ]] && [[ "${height}" -gt "${min_inactive_height}" ]]; then
      # Resize surrounding rows if greater than min as otherwise it will only change downwards and right.
      resize_height_panes+=("${id}")
    elif [[ "${left}" -le "${active_left}" ]] && [[ "${right}" -ge "${active_right}" ]] && [[ "${height}" -gt "${min_inactive_height}" ]]; then
      # Resize pane if within or greater than active pane, this allows for above and below panes to be bigger.
      resize_height_panes+=("${id}")
    fi
  done
fi

resize_width_panes=()
v_inactive_pane_count=-1
if [[ "${resize_width_setting}" == "true" ]] && [[ "${width_resize_required}" == "true" ]]; then
  for pane in ${vertical_panes}; do
    IFS=- read -r right top bottom active id width < <(echo "${pane}")

    if [[ "${bottom}" -eq "${active_bottom}" ]]; then
      # Count splits on active row
      ((v_inactive_pane_count=v_inactive_pane_count+1))
    fi

    if [[ "${active}" -eq 1 ]]; then
      resize_width_panes+=("${id}")
      continue
    fi

    if [[ "${right}" -ne "${active_right}" ]] && [[ "${height}" -gt "${min_inactive_height}" ]]; then
      # Resize surrounding columns if greater than min as otherwise it will only change downwards and right.
      resize_height_panes+=("${id}")
    elif [[ "${top}" -le "${active_top}" ]] && [[ "${bottom}" -ge "${active_bottom}" ]] && [[ "${width}" -gt "${min_inactive_width}" ]]; then
      # Resize pane if within or greater than active pane, this allows for above and below panes to be bigger.
      resize_width_panes+=("${id}")
    fi
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
echo "inactive pane counts in active - row: ${v_inactive_pane_count}, column: ${h_inactive_pane_count}"

exit 0
