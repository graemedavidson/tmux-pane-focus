#!/usr/bin/env bash

# Check session and then global (default in .tmux.conf), set session
read -r ACTIVE_PERCENTAGE< <(tmux show-options -qv "@pane-focus-size")
if [[ -z "${ACTIVE_PERCENTAGE}" ]]; then
  read -r ACTIVE_PERCENTAGE< <(tmux show-options -gqv "@pane-focus-size")
  if [[ -z "${ACTIVE_PERCENTAGE}" ]]; then
    tmux set-option "@pane-focus-size" "50"
  else
    tmux set-option "@pane-focus-size" "${ACTIVE_PERCENTAGE}"
  fi
fi

tmux display-menu -T "#[align=centre fg=green]Pane Focus Options" -x R -y P \
  "" \
  "-Current: ${ACTIVE_PERCENTAGE}" "" "" \
  "" \
  "50%"         "5" "set-option \"@pane-focus-size\" \"50\"" \
  "60%"         "6" "set-option \"@pane-focus-size\" \"60\"" \
  "70%"         "7" "set-option \"@pane-focus-size\" \"70\"" \
  "80%"         "8" "set-option \"@pane-focus-size\" \"80\"" \
  "90%"         "9" "set-option \"@pane-focus-size\" \"90\"" \
  "off"         "o" "set-option \"@pane-focus-size\" \"off\"" \
  "" \
  "Close menu"  "q" ""
