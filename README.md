# tmux pane focus

[![codecov](https://codecov.io/gh/graemedavidson/tmux-pane-focus/branch/main/graph/badge.svg?token=2ULOAGT6BT)](https://codecov.io/gh/graemedavidson/tmux-pane-focus)

Tmux plugin to auto resize panes on focus similar to [nvim Focus](https://github.com/beauwilliams/focus.nvim).
On focusing on another pane the hook `after-select-pane` calls the focus script.

Auto resize size and direction set for all windows in the `.tmux.conf` file and then overridden locally via the options
menu.

- Size: >=50, <100.
- Direction:
  - `+`: both
  - `|`: vertical (width) changes only
  - `-`: horizontal (height) changes only

```conf
set -g @pane-focus-size '50'
set -g @pane-focus-size '+'
```

Change size setting per session by activating menu with tmux shortcut: `ctrl-a T`.

Add current active size to status bar:

```conf
set -g status-right '#[fg=colour255,bg=colour237][#{@pane-focus-direction}][#{@pane-focus-size}]#[fg=default,bg=default]'
```

## Installation

Clone repo into tmux plugins dir.

Add run shell command to end of `.tmux.conf` file to activate plugin.

```conf
run-shell '~/.tmux/plugins/tmux-pane-focus/focus.tmux'
```

ToDo: review installing plugin via [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)

## Architecture

Currently plugin determines window and appropriate pane size for active and inactive and then resizes all panes on an
plane. So resize panes top to bottom and left to right.

Plugin language is bash matching the majority of tmux plugins. Bash allows for portability but the language has
limitations. Considerations to moving towards another scripting language for example python in pipeline.

## Local Development

Local development leverages a basic docker compose and docker file setup. Setup should respond to changes made to the
scripts without requiring restarts.

- [Docker Build File](./Dockerfile)
- [Docker Compose](./docker-compose.yml)

Build the local image and run:

```bash
docker-compose build
docker-compose run tmux
```

Create and move between new panes:

| Binding                   | Action
| ---                       | ---
| `ctrl-a |`                | Create vertical pane
| `ctrl-a -`                | Create horizontal pane
| `ctrl-a <DIRECTION_KEY>`  | Move between panes
| `ctrl-a T`                | Pane Focus menu to change percentage for active pane

### Shellspec Tests

Unit tests included through [shellspec](https://shellspec.info/) within a [container](https://hub.docker.com/r/shellspec/shellspec-debian/tags).

- [Tests](./spec/)

```bash
docker-compose run tests
docker run -it --rm -v "$PWD:/src" --entrypoint bash shellspec/shellspec-debian:0.28.1
```

### Tmux Setup

Tmux configured to use `ctrl-a` as well as other opinionated settings.

- [tmux config](./.tmux.conf)

[Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) included with automatic installation of
[Tmux Sensible](https://github.com/tmux-plugins/tmux-sensible).

### Pre-Commit

[Pre-Commit](https://pre-commit.com/).

- [./.pre-commit-config.yaml]

Install pre-commit hooks:

```bash
pre-commit install
```

Run against all files:

```bash
pre-commit run --all-files
```
