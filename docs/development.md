# Local Development

Local development leverages a basic docker compose and docker file setup. Setup should respond to changes made to the
scripts without requiring restarts.

- [Docker Build File](../Dockerfile)
- [Docker Compose](../docker-compose.yml)

Build the local image and run:

```bash
docker-compose build
docker-compose run tmux
```

Create and move between new panes:

Binding actions:

- `ctrl-a |`: Create vertical pane
- `ctrl-a -`: Create horizontal pane
- `ctrl-a <DIRECTION_KEY>`: Move between panes
- `ctrl-a T`: plugin settings menu

## Shellspec Tests

Unit tests included through [shellspec](https://shellspec.info/) within a [container](https://hub.docker.com/r/shellspec/shellspec-debian/tags).

- [Tests](../spec/)

```bash
docker-compose run tests
docker run -it --rm -v "$PWD:/src" --entrypoint bash shellspec/shellspec-debian:0.28.1
```

## Tmux Setup

Tmux configured to use `ctrl-a` as well as other opinionated settings.

- [tmux config](../.tmux.conf)

[Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) included with automatic installation of
[Tmux Sensible](https://github.com/tmux-plugins/tmux-sensible).

## Pre-Commit

[Pre-Commit](https://pre-commit.com/).

- [.pre-commit-config.yaml](../.pre-commit-config.yaml)

Install pre-commit hooks:

```bash
pre-commit install
```

Run against all files:

```bash
pre-commit run --all-files
```
