# tmux pane focus

[![codecov](https://codecov.io/gh/graemedavidson/tmux-pane-focus/branch/main/graph/badge.svg?token=2ULOAGT6BT)](https://codecov.io/gh/graemedavidson/tmux-pane-focus)

Tmux plugin to auto resize panes on focus similar to [nvim Focus](https://github.com/beauwilliams/focus.nvim).

Utilises [tmux hooks](./docs/tmux.md#hooks) to react to the creation and selection of panes.

- Size: >=50, <100.
- Direction:
  - `+`: both
  - `|`: width changes only
  - `-`: height changes only

Plugin still in an alpha stage. Currently testing locally to confirm features and find bugs. A refactor is coming as
currently not in a DRY state with a lack of naming clarity and commenting hindering contributing. Feel free to use
though and open an issue or start a discussion.

## Installation

### Tmux Plugin Manager

Add plugin GitHub url to list of tpm plugins. Specify tag/branch for specific version.

```
set -g @plugin 'graemedavidson/tmux-pane-focus'
# set -g @plugin 'graemedavidson/tmux-pane-focus#tag'
```

### Manual

Clone repo into tmux plugins dir.

Add run shell command to end of `.tmux.conf` file to activate plugin.

```conf
run-shell '~/.tmux/plugins/tmux-pane-focus/focus.tmux'
```

## Configuration

Changes to configuration require a tmux config reload or new tmux session to pickup changes. Adding the following 
configuration can simply the process for testing which also requires a restart to start using.

```bash
bind R source-file ~/.tmux.conf \; display-message "Config reloaded..."
```

Enable/Disable plugin:

```
set -g @pane-focus-size on
```

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
