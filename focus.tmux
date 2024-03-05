#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux set-hook -g after-select-pane "run-shell '$CURRENT_DIR/scripts/focus.sh'"
tmux set-hook -g after-split-window "run-shell '$CURRENT_DIR/scripts/focus.sh'"

tmux bind-key T run-shell "$CURRENT_DIR/scripts/menu.sh"
