# Module: `router`

`internal/router` selects where a model request runs. It contains group and matrix local implementations plus peer routing.

## Key files

- [`router.go`](../../../internal/router/router.go) — router interfaces and shared server behavior.
- [`group.go`](../../../internal/router/group.go) — group-based local routing.
- [`matrix.go`](../../../internal/router/matrix.go) — matrix-based routing.
- [`matrix_solver.go`](../../../internal/router/matrix_solver.go) — matrix decision solving.
- [`peer.go`](../../../internal/router/peer.go) — remote peer routing.

## Public surface

`NewGroup`, `NewMatrix`, and `NewPeer` construct implementations selected by `config.Routing`. Local routers expose model state and forwarding operations consumed by `server.Server`.

## Design

Group routing organizes models into configured groups with swap/exclusive/persistent semantics. Matrix routing evaluates declarative constraints and decisions. Peer routing represents configured remote destinations separately from local process ownership.
