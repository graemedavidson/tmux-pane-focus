#!/usr/bin/env bash
#
# Records demo.sh's scripted tmux session with asciinema and renders it to a
# GIF with agg, entirely inside the container -- no host-installed
# asciinema/agg required. Writes both files to OUT_DIR, which the cast
# service mounts to ./bin so the result lands in the repo ready to embed.
#
# There's no host terminal attached to this container, so asciinema has
# nothing to allocate a pty from and errors out immediately. `script` gives
# it a real one regardless -- but that pty starts sized 0x0 (nothing ever
# ioctls a size onto it), which asciinema records verbatim and agg then
# refuses to render, so `stty` sets a size explicitly before recording.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PLUGIN_DIR
readonly OUT_DIR="${1:-/home/developer/bin}"

mkdir -p "${OUT_DIR}"

script -qc "
  export TERM=xterm
  stty rows 30 cols 120
  asciinema rec '${OUT_DIR}/demo.cast' --overwrite --command '${PLUGIN_DIR}/demo/demo.sh'
" /dev/null

agg "${OUT_DIR}/demo.cast" "${OUT_DIR}/demo.gif"
