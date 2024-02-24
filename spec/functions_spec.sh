#!/bin/shellspec shell=bash

Describe 'check get_active_pane'
  Include scripts/functions.sh

  # window height
  # window width
  # active percentage
  # mock data (index height width top bottom left right)
  # result (index resize_height resize_width min_height min_width top bottom left right height width)
  Parameters
    100 100 50 "0-50-100-0-49-0-99" "0-false-false-49-49-0-49-0-99-50-100"
    100 100 60 "0-50-100-0-49-0-99" "0-true-false-59-59-0-49-0-99-50-100"
    100 100 70 "0-50-100-0-49-0-99" "0-true-false-69-69-0-49-0-99-50-100"
    100 100 80 "0-50-100-0-49-0-99" "0-true-false-79-79-0-49-0-99-50-100"
    100 100 90 "0-50-100-0-49-0-99" "0-true-false-89-89-0-49-0-99-50-100"

    100 100 50 "0-25-25-0-49-0-99" "0-true-true-49-49-0-49-0-99-25-25"
    100 100 60 "0-25-25-0-49-0-99" "0-true-true-59-59-0-49-0-99-25-25"
    100 100 70 "0-25-25-0-49-0-99" "0-true-true-69-69-0-49-0-99-25-25"
    100 100 80 "0-25-25-0-49-0-99" "0-true-true-79-79-0-49-0-99-25-25"
    100 100 90 "0-25-25-0-49-0-99" "0-true-true-89-89-0-49-0-99-25-25"

    1000 1000 50 "0-250-250-0-249-0-249" "0-true-true-499-499-0-249-0-249-250-250"
  End

  It 'returns correct values for active pane'

    shellspec_mock tmux <<-EOF
echo "${4}"
EOF

    When call get_active_pane "${1}" "${2}" "${3}"
    The output should eq "${5}"
  End
End

Describe 'check in_col_row'
  Include scripts/functions.sh

  # side a
  # side a active
  # side b
  # side b active
  # result (bool)
  Parameters
    0 0 100 100 true
    0 50 100 100 true
    25 0 100 100 true
    0 25 125 100 true

    0 50 49 100 false
    51 0 100 50 false
    0 75 25 100 false
    75 0 100 50 false
  End

  It 'returns true if inactive pane within boundaries of active pane, other false'
    When call in_col_row "${1}" "${2}" "${3}" "${4}"
    The output should eq "${5}"
  End
End

Describe 'check get_inactive_pane_size'
  Include scripts/functions.sh

  # window size
  # active percentage
  # number of panes
  # result (minimum inactive pane size)
  Parameters
    100 50 1 50
    100 60 1 40
    100 70 1 30
    100 80 1 20
    100 90 1 10

    100 50 2 25
    100 60 2 20
    100 70 2 15
    100 80 2 10
    100 90 2 5

    # Bash uses integer maths, so rounds down to whole numbers
    100 50 3 16
    100 60 3 13
    100 70 3 10
    100 80 3 6
    100 90 3 3
  End

  It 'return the minimum size of an inactive pane'
    When call get_inactive_pane_size "${1}" "${2}" "${3}"
    The output should eq "${4}"
  End
End

Describe 'check get_tmux_option'
  Include scripts/functions.sh

  # option
  # default value
  # mock result (-w)
  # mock result (-g)
  # result (option value)
  Parameters
    "@pane-focus-enabled" "on" "on" "" "on"
    "@pane-focus-enabled" "on" "" "on" "on"
    "@pane-focus-enabled" "on" "" "" "on"
    "@pane-focus-enabled" "on" "off" "" "off"
    "@pane-focus-enabled" "on" "" "off" "off"

    "@pane-focus-size" "50" "50" "" "50"
    "@pane-focus-size" "50" "" "50" "50"
    "@pane-focus-size" "50" "" "" "50"
    "@pane-focus-size" "50" "60" "" "60"
    "@pane-focus-size" "50" "" "60" "60"

    "@pane-focus-direction" "+" "+" "" "+"
    "@pane-focus-direction" "+" "" "+" "+"
    "@pane-focus-direction" "+" "" "" "+"
    "@pane-focus-direction" "+" "|" "" "|"
    "@pane-focus-direction" "+" "" "|" "|"
    "@pane-focus-direction" "+" "-" "" "-"
    "@pane-focus-direction" "+" "" "-" "-"
  End

  set_tmux_option() {
    echo "" > /dev/null
  }

  tmux() {
    local sub_command="${1}"
    local flags="${2}"

    if [[ "${sub_command}" == "show-options" ]]; then
      if [[ "${flags}" == "-wqv" ]]; then
        echo "${window_val}"
      elif [[ "${flags}" == "-gqv" ]]; then
        echo "${global_val}"
      fi
    fi
  }

  It 'returns set value or default'
    export -a window_val="${3}"
    export -a global_val="${4}"

    When call get_tmux_option "${1}" "${2}"
    The output should eq "${5}"
  End
End

Describe 'check get_inactive_parent_pane_count'
  Include scripts/functions.sh

  Parameters
    0 0
    0 0 0 0
    0 0 0 0 0 0 0 0 0 0 0
    1 0 0 0 1 0 0 0 0 0 0
    2 0 0 0 1 1 0 0 0 0 0
    4 0 0 0 1 1 0 0 0 1 1
  End

  Describe "Functionality with parameter (result): $1 and array (test data): ${*:2}"
    It 'returns count of inactive parent panes'
      expected_result="$1"
      array_values=("${@:2}")

      When call get_inactive_parent_pane_count "${array_values[@]}"
      The output should eq "${expected_result}"
    End
  End
End
