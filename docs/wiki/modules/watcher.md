# Module: `watcher`

`internal/watcher` is a portable configuration file watcher based on `os.Stat` polling rather than inotify.

## Key files

- [`watcher.go`](../../../internal/watcher/watcher.go) — `Watcher`, polling loop, and change detection.
- [`dirwatcher.go`](../../../internal/watcher/dirwatcher.go) — directory-level watching.

## Public surface

`Watcher` has `Path`, `Interval`, and `OnChange`; `Run(ctx)` blocks until cancellation. `DefaultInterval` is two seconds.

## Gotchas

The initial stat establishes a baseline and does not invoke the callback. Present-to-missing transitions stay quiet to tolerate rename-style writes; missing-to-present and metadata changes trigger reload callbacks.
