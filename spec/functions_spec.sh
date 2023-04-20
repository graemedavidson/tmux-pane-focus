#!/bin/shellspec shell=bash

# Test Data
# pl1="$(cat <<-END
# 10
# END
# )"

# pl2="$(cat <<-END
# 10
# 20
# 30
# END
# )"

# pl3="$(cat <<-END
# 10
# 20
# 20
# END
# )"

# Describe 'check get_split_count'
#   Include scripts/functions.sh

#   Parameters
#     "right" "${pl1}" 0
#     "left" "${pl1}" 0
#     "right" "${pl2}" 2
#     "left" "${pl2}" 2
#     "right" "${pl3}" 1
#     "left" "${pl3}" 1
#   End

#   It 'returns correct number of splits'

#     shellspec_mock tmux <<-EOF
# echo "${2}"
# EOF

#     When call get_split_count "${1}"
#     The output should eq "${3}"
#   End
# End

# Describe 'check get_settings'
#   Include scripts/functions.sh

#   # split_count window_size active_percentage result(active_percentage-inactive_percentage-min_active-min_inactive)
#   Parameters
#     0 100 50 "100-100-100-100"
#     0 200 50 "100-100-200-200"
#     1 100 50 "50-50-50-50"
#     1 200 50 "50-50-100-100"
#     3 1000 50 "50-16-500-160"
#     1 1000 60 "60-40-600-400"
#     1 1000 70 "70-30-700-300"
#     1 1000 80 "80-20-800-200"
#     1 1000 90 "90-10-900-100"
#     2 1000 60 "60-20-600-200"
#     2 1000 70 "70-15-700-150"
#     2 1000 80 "80-10-800-100"
#     2 1000 90 "90-5-900-50"
#   End

#   It 'returns correct pane settings'
#     When call get_settings "${1}" "${2}" "${3}"
#     The output should eq "${4}"
#   End
# End

# Does not have any outputs to test
# ToDo: review adding a debug output?
# Describe 'check resize_pane'
#   Include scripts/functions.sh

#   Parameters
#   End

#   It 'correctly resizes pane'
#     When call resize_pane
#     The output should eq
#   End
# End

# Describe 'check check_active_pane'
#   Include scripts/functions.sh

#   Parameters
#     99 99 "100-100" "false-false"
#     100 100 "100-100" "false-false"
#     200 200 "100-100" "true-true"
#   End

#   It 'returns correct resize results'

#     shellspec_mock tmux <<-EOF
# echo "${3}"
# EOF

#     When call check_active_pane "${1}" "${2}"
#     The output should eq "${4}"
#   End
# End
