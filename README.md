# tmux pane focus

[![codecov](https://codecov.io/gh/graemedavidson/tmux-pane-focus/branch/main/graph/badge.svg?token=2ULOAGT6BT)](https://codecov.io/gh/graemedavidson/tmux-pane-focus)

Tmux plugin to auto resize panes on focus similar to [nvim Focus](https://github.com/beauwilliams/focus.nvim).
On focusing on another pane the hook `after-select-pane` calls the focus script.

- Size: >=50, <100.
- Direction:
  - `+`: both
  - `|`: width changes only
  - `-`: height changes only


## Installation

### Tmux Plugin Manager


### Manual

Clone repo into tmux plugins dir.

Add run shell command to end of `.tmux.conf` file to activate plugin.

```conf
run-shell '~/.tmux/plugins/tmux-pane-focus/focus.tmux'
```

## Configuration

Add configuration to the `.tmux.conf` file to override the following defaults:

- focus size:       `50%`
- focus direction:  `+`

```conf
set -g @pane-focus-size '50'
set -g @pane-focus-direction '+'
```

### Settings Menu

The default and global settings can be overridden at the window level through an options menu.

tmux shortcut: `ctrl-a T`.

### Status bar

Add current active size and direction to status bar:

```conf
set -g status-right '#[fg=colour255,bg=colour237][#{@pane-focus-direction}][#{@pane-focus-size}]#[fg=default,bg=default]'
```
