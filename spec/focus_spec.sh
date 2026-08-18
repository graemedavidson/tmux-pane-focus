#!/bin/shellspec shell=bash

Describe 'check main flushes queued resizes'
  Include scripts/focus.sh

  # Two panes, side by side, in a 120x30 window with @pane-focus-size 70:
  # pane 1 (active) is 59 columns wide, short of the 83-column minimum, so
  # main() should queue a resize for both panes and flush them as one
  # tmux invocation. Regression test for the "AI Based refactor" dropping
  # the flush_resize_panes call that scripts/functions.sh's resize_pane()
  # relies on (main() would otherwise queue resizes that never apply).
  tmux() {
    case "$1" in
      list-panes)
        if [[ "$2" == "-F" ]]; then
          case "$3" in
            "#{pane_index}-#{pane_height}-#{pane_width}-#{pane_top}-#{pane_bottom}-#{pane_left}-#{pane_right}")
              echo "1-30-59-0-29-61-119"
              ;;
            "#{pane_index}-#{pane_left}-#{pane_top}-#{pane_right}-#{pane_bottom}-#{pane_active}")
              printf '0-0-0-60-29-0\n1-61-0-119-29-1\n'
              ;;
          esac
        else
          printf '0\n1\n'
        fi
        ;;
      list-windows)
        echo "30-120"
        ;;
      show-options)
        [[ "$3" == "@pane-focus-size" ]] && echo "70"
        ;;
      resize-pane)
        echo "$*"
        ;;
    esac
  }

  It 'applies every queued resize as a single tmux invocation'
    When call main
    The output should eq "resize-pane -t 0 -x 36 ; resize-pane -t 1 -x 83"
  End
End
