#!/usr/bin/env bash
#
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Not working: shellcheck source=./scripts/functions.sh
# shellcheck source=/dev/null
. "${current_dir}/functions.sh"

read -r enabled< <(get_tmux_option "@pane-focus-enabled" "on")
read -r active_percentage< <(get_tmux_option "@pane-focus-size" "50")
read -r direction< <(get_tmux_option "@pane-focus-direction" "+")

tmux display-menu -T "#[align=centre fg=green]Pane Focus Options" -x R -y P \
  "" \
  "-Pane Size: ${active_percentage}%" "" "" \
  "50%"         "5" "set-option -w \"@pane-focus-size\" \"50\"" \
  "60%"         "6" "set-option -w \"@pane-focus-size\" \"60\"" \
  "70%"         "7" "set-option -w \"@pane-focus-size\" \"70\"" \
  "80%"         "8" "set-option -w \"@pane-focus-size\" \"80\"" \
  "90%"         "9" "set-option -w \"@pane-focus-size\" \"90\"" \
  "" \
  "-Focus Direction: ${direction}" "" "" \
  "[+] both"            "b" "set-option -w \"@pane-focus-direction\" \"+\"" \
  "[|] vertical only"   "v" "set-option -w \"@pane-focus-direction\" \"|\"" \
  "[-] horizontal only" "h" "set-option -w \"@pane-focus-direction\" \"-\"" \
  "" \
  "-Enabled: ${enabled}" "" "" \
  "on"          "o" "set-option -w \"@pane-focus-enabled\" \"on\"" \
  "off"         "f" "set-option -w \"@pane-focus-enabled\" \"off\"" \
  "" \
  "Close menu"  "q" ""
