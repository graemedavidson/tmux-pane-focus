.PHONY: build tmux test record cast clean

# Build the dev/plugin image used by the tmux, record, cast, and (implicitly) test flows.
build:
	docker compose build tmux

# Attach to an interactive tmux session with the plugin mounted live for manual testing.
tmux:
	docker compose run --rm tmux

# Run the shellspec unit test suite.
test:
	docker compose run --rm tests

# Record an asciinema cast of the scripted demo (see demo/demo.sh) using a
# host-installed asciinema, so you can watch it happen in your own terminal.
# Requires asciinema on the host: https://asciinema.org/docs/installation
record:
	asciinema rec demo.cast -c "docker compose run --rm record"

# Render the scripted demo straight to bin/demo.cast and bin/demo.gif,
# entirely inside the container -- no host asciinema/agg required. This is
# what the README's embedded GIF is built from.
cast:
	mkdir -p bin
	docker compose run --rm cast

clean:
	docker compose down --rmi local
