# Module: `docagent`

`internal/docagent` packages the embedded knowledge base and exposes documentation search/reference behavior used by the Playground agent and MCP integration.

## Key files

- [`kb.go`](../../../internal/docagent/kb.go) — knowledge-base representation and loading.
- [`search.go`](../../../internal/docagent/search.go) — search behavior.
- [`reference.go`](../../../internal/docagent/reference.go) — reference access.
- [`configdoc.go`](../../../internal/docagent/configdoc.go) — configuration documentation.
- [`schema.go`](../../../internal/docagent/schema.go) — schema-facing documentation support.

## Integration

`server.Server` stores an optional `*docagent.Docs` reference. The server can expose it through `/api/mcp`; the composition root wires embedded docs when constructing the server.

## Scope

This wiki records the integration boundary; the knowledge base content itself is maintained under `docs/` and is not treated as a core runtime module here.
