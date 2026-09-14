# Module: `server`

`internal/server` owns the HTTP server, middleware, endpoint registration, request classification, and dispatch to local or peer routers.

## Key files

- [`server.go`](../../../internal/server/server.go) — `Server`, route tables, construction, and lifecycle.
- [`api.go`](../../../internal/server/api.go) — model listing and API handlers.
- [`auth.go`](../../../internal/server/auth.go) — API-key middleware.
- [`apimcp.go`](../../../internal/server/apimcp.go) — MCP JSON-RPC surface.
- [`metrics.go`](../../../internal/server/metrics.go) — request/activity metrics.

## Public surface

`New` constructs a `Server` from config, routers, monitors, store, build metadata, hardware, and docs. `Server` exposes HTTP serving through its configured handler and methods such as `SetTailcatAddress`, `TailcatAddress`, and `ActiveProfile`.

## Dispatch

Model IDs can arrive in JSON, form data, or query parameters. Route lists in `server.go` define which requests are model-dispatched; `/v1/models` combines local, alias, and peer records.
