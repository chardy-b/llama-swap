# llama-swap Code Wiki

This bounded wiki describes the checked-out `llama-swap` Go source at commit `21bc145a6fa6198c4d856fbb0830845c472b0ae4`. llama-swap loads YAML configuration, selects local or peer model backends, starts and supervises upstream processes, and exposes HTTP APIs compatible with common inference clients.

## Entry points

- [`llama-swap.go`](../../llama-swap.go) — CLI, configuration loading, process-wide wiring, listeners, and shutdown.
- [`internal/server/server.go`](../../internal/server/server.go) — HTTP server construction and dispatch.
- [`internal/config/load.go`](../../internal/config/load.go) — YAML, macro, default, and validation pipeline.

## Architecture

Configuration becomes a normalized `config.Config`; `server.Server` constructs local and peer routers, while the router owns model selection and process lifecycle. HTTP handlers forward model requests to a selected `process.Process`, and logs, events, metrics, and SQLite activity storage provide observability.

See [architecture](architecture.md), [sequences](diagrams/sequences.md),
[getting started](getting-started.md), and the
[native Windows deployment guide](../setup/windows-native.md).

## Module map

| Module | Source | Focus |
|---|---|---|
| config | [`internal/config`](../../internal/config) | YAML schema, defaults, normalization |
| server | [`internal/server`](../../internal/server) | HTTP routes, middleware, API surface |
| router | [`internal/router`](../../internal/router) | Local/group/matrix/peer selection |
| process | [`internal/process`](../../internal/process) | Upstream process lifecycle and proxying |
| store | [`internal/store`](../../internal/store) | SQLite migrations and activity data |
| event | [`internal/event`](../../internal/event) | Typed asynchronous event dispatch |
| watcher | [`internal/watcher`](../../internal/watcher) | Polling-based config change detection |
| docagent | [`internal/docagent`](../../internal/docagent) | Embedded documentation knowledge base/search |

## Scope

This is a source-reference snapshot, not exhaustive API documentation. Tests, generated UI assets, platform probes, and command utilities are intentionally outside the initial module set.
