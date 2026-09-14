# Module: `process`

`internal/process` wraps an upstream command and provides synchronized lifecycle control and HTTP forwarding.

## Key files

- [`process.go`](../../../internal/process/process.go) — process abstraction and state machine.
- [`process_command.go`](../../../internal/process/process_command.go) — command-backed implementation.
- [`runtime_unix.go`](../../../internal/process/runtime_unix.go) — Unix process runtime.
- [`runtime_windows.go`](../../../internal/process/runtime_windows.go) — Windows runtime behavior.

## Public surface

The process interface includes `Run`, `EnsureReady`, `Stop`, `State`, `ServeHTTP`, and `Logger`. `EnsureReady` makes readiness decisions inside the state machine to avoid races between concurrent callers.

## Lifecycle

A command is started with configured environment/port substitutions, monitored until its health endpoint is ready, then served. Stop waits for termination and platform-specific tree cleanup handles descendant processes.
