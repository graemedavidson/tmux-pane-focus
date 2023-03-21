#!/usr/bin/env bash

get_env_var () {
  VARIABLE="FOCUS_PANE_$1"
  VALUE=$(tmux show-environment -g "${VARIABLE}" 2>&1)
  retval=${VALUE#*=}
  echo "$retval"
}

getval=$(get_env_var "HEIGHT")
echo "${getval}"


getval=$(get_env_var "WIDTH")
echo "${getval}"
