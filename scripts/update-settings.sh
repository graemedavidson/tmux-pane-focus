#!/usr/bin/env bash
#
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Not working: shellcheck source=./scripts/functions.sh
# shellcheck source=/dev/null
. "${CURRENT_DIR}/functions.sh"

read -r ACTIVE_PERCENTAGE< <(get_tmux_option "@pane-focus-size" "50")
read -r DIRECTION< <(get_tmux_option "@pane-focus-direction" "+")

tmux display-menu -T "#[align=centre fg=green]Pane Focus Options" -x R -y P \
  "" \
  "-Pane Size: ${ACTIVE_PERCENTAGE}" "" "" \
  "50%"         "5" "set-option \"@pane-focus-size\" \"50\"" \
  "60%"         "6" "set-option \"@pane-focus-size\" \"60\"" \
  "70%"         "7" "set-option \"@pane-focus-size\" \"70\"" \
  "80%"         "8" "set-option \"@pane-focus-size\" \"80\"" \
  "90%"         "9" "set-option \"@pane-focus-size\" \"90\"" \
  "off"         "o" "set-option \"@pane-focus-size\" \"off\"" \
  "" \
  "-Focus Direction: ${DIRECTION}" "" "" \
  "[+] both"            "b" "set-option \"@pane-focus-direction\" \"+\"" \
  "[|] vertical only"   "v" "set-option \"@pane-focus-direction\" \"|\"" \
  "[-] horizontal only" "h" "set-option \"@pane-focus-direction\" \"-\"" \
  "" \
  "Close menu"  "q" ""
