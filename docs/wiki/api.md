# HTTP API

The HTTP surface is implemented in [`internal/server`](../../internal/server). Route registration and middleware are assembled by [`internal/server/server.go`](../../internal/server/server.go); model-list rendering is in [`internal/server/api.go`](../../internal/server/api.go).

## OpenAI-compatible model endpoints

- `GET /v1/models` — lists configured local models, optional aliases, and peer models; status reports loaded/unloaded state.
- `POST /v1/chat/completions` — model-dispatched chat completion forwarding.
- `POST /v1/completions` — model-dispatched completion forwarding.
- `POST /v1/responses` — model-dispatched responses forwarding.
- `POST /v1/embeddings` — model-dispatched embedding forwarding.

The server also declares model-dispatched routes for messages, reranking, audio, images, Stable Diffusion, completion, and infill. Exact route arrays are the source of truth in `server.go`.

## Management and observability

The server exposes API handlers for version/build information, logs, activity/metrics, model state, profiles, configuration-related operations, and health/status. Names and authorization behavior should be read from route registration in [`server.go`](../../internal/server/server.go), [`api.go`](../../internal/server/api.go), and [`auth.go`](../../internal/server/auth.go).

## MCP and documentation

`/api/mcp` is implemented by [`internal/server/apimcp.go`](../../internal/server/apimcp.go) and uses the tool registry in [`internal/mcptools`](../../internal/mcptools). Embedded documentation support is provided by [`internal/docagent`](../../internal/docagent).

## Authentication

Configured API keys are handled by [`internal/server/auth.go`](../../internal/server/auth.go). Do not assume an endpoint is public when deploying: inspect the configured middleware and supply keys according to the deployment's policy.
