# CHANGELOG
https://keepachangelog.com/en/1.0.0/

## [v1.0.0] - 17/08/26

### Changed

- Refactored `scripts/focus.sh` from a single monolithic script into named functions (validation, pane-geometry calculation, resizing, debug logging), sharing logic between the height and width dimensions instead of duplicating it.
- `validate_direction` now checks the direction against an exact set (`+`, `|`, `-`) instead of an unanchored regex that could match invalid values (e.g. `+x`).
- Bumped `Dockerfile` base image to `ubuntu:jammy-20260731.1`, `tmux` to `3.7b`, and pinned apt package versions to current; added `asciinema`, `agg`, and `fonts-dejavu-core` for the demo pipeline.

### Fixed

- Pane resizing was silently broken on this branch: `resize_pane()` only queues a `resize-pane` command (batched since the "batch-resize-redraws" change), but nothing called `flush_resize_panes()` to apply the queue, so no pane was ever actually resized. Added the missing call.

## [v0.5.0-alpha] - 17/07/26

### Added

- Batch `resize-pane` calls into a single `tmux` invocation, so the client redraws once for the final layout instead of once per pane. (#62)

### Changed

- Documented that tmux config changes require a config reload to take effect. (#45)
- Bumped `ubuntu` base image: `jammy-20240212` → `jammy-20240427` → `jammy-20250126` → `jammy-20250404`. (#41, #47, #49)
- Bumped `codecov/codecov-action` from 4 to 5. (#46)

### Fixed

- Fixed typo in README. (#57)

## [v0.4.0-alpha] - 05/03/24

### Added

- hook to resize when creating new panes within a window.

### Fixed

- debug log option using incorrect value when set in menu.

## [v0.3.0-alpha] - 25/02/24

### Added

- Basic releases workflow to generate GitHub release when pushing a tag.
    - Define release config for use with issue labelling
- Changelog
