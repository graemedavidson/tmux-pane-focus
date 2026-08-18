# Tmux

## Hooks

Pane Focus utilises tmux hooks to activate the script, so it runs on its own whenever you switch or create a pane —
there's no keybinding to trigger it. [`focus.tmux`](../focus.tmux) registers two:

```bash
tmux set-hook -g after-select-pane "run-shell '.../scripts/focus.sh'"
tmux set-hook -g after-split-window "run-shell '.../scripts/focus.sh'"
```

- `after-select-pane`: fires when focus moves to a different pane (e.g. clicking a pane, or the plugin's own
  `Alt+<Arrow>` bindings).
- `after-split-window`: fires when a new pane is created, since the new pane becomes active immediately.

Both run [`scripts/focus.sh`](../scripts/focus.sh) via `run-shell`, which reads the current configuration and pane
layout and resizes accordingly (see [Architecture](./architecture.md)).

`focus.tmux` also binds the settings menu directly, outside of a hook:

```bash
tmux bind-key T run-shell '.../scripts/menu.sh'
```

List available hooks for session, window, and pane. The list includes hooks currently configured.

```bash
tmux show-hooks -s # show all hooks available for the session.
```
