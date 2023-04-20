#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux set-hook -g after-select-pane "run-shell '$CURRENT_DIR/scripts/test-3.sh'"

tmux bind-key T run-shell "$CURRENT_DIR/scripts/update-settings.sh"
