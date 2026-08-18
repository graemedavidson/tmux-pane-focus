# Local Development

Local development leverages a basic docker compose and docker file setup. Setup should respond to changes made to the
scripts without requiring restarts.

- [Docker Build File](../Dockerfile)
- [Docker Compose](../docker-compose.yml)
- [Makefile](../Makefile)

A [Makefile](../Makefile) wraps the common compose commands:

```bash
make build   # build the dev/plugin image
make tmux    # attach to an interactive tmux session with the plugin mounted live
make test    # run the shellspec unit test suite
make record  # record an asciinema cast of the scripted demo, using a host-installed asciinema
make cast    # render the scripted demo straight to bin/demo.cast and bin/demo.gif, entirely in-container
make clean   # tear down containers and remove locally built images
```

Equivalent directly through `docker compose`, if you'd rather not use `make`:

```bash
docker compose build tmux
docker compose run --rm tmux
```

Create and move between new panes:

Binding actions:

- `ctrl-a |`: Create vertical pane
- `ctrl-a -`: Create horizontal pane
- `ctrl-a+<DIRECTION_ARROW>`: Move between panes (no prefix needed)
- `ctrl-a T`: plugin settings menu

## Shellspec Tests

Unit tests included through [shellspec](https://shellspec.info/) within a [container](https://hub.docker.com/r/shellspec/shellspec-debian/tags).

- [Tests](../spec/)

```bash
make test
# or directly:
docker compose run --rm tests
docker run -it --rm -v "$PWD:/src" --entrypoint bash shellspec/shellspec-debian:0.28.1
```

## Demo Recording

The README's demo GIF is generated from a scripted tmux session rather than recorded by hand.

- [Demo scripts](../demo/)
  - [`demo.sh`](../demo/demo.sh) drives a real tmux session through splits, focus changes, and the settings menu using
    native tmux commands (not simulated keypresses).
  - [`record.sh`](../demo/record.sh) wraps `demo.sh` with `asciinema` and renders the cast to a GIF with `agg`.

```bash
make cast  # bin/demo.cast and bin/demo.gif, entirely in-container
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
