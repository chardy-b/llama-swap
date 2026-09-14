# Getting Started

## Prerequisites

The module declares Go `1.27.1` in [`go.mod`](../../go.mod). A runnable upstream inference command (for example `llama-server`) and a model file are required; llama-swap launches the command described by each model's `cmd` field.

For a native Windows deployment with llama.cpp, CUDA, API-key setup, and
Tailscale Serve, use the [native Windows setup guide](../setup/windows-native.md).

## Build

From the repository root:

```bash
go build -o llama-swap .
```

The repository also provides Make targets; `make linux-amd64` builds with embedded UI assets after installing UI dependencies.

## Minimal configuration

```yaml
models:
  example:
    cmd: |
      /path/to/llama-server --host 127.0.0.1 --port ${PORT} --model /path/to/model.gguf
```

`${PORT}` is supplied by the process manager. The complete example is [`config.example.yaml`](../../config.example.yaml), which points to [`docs/config.example.yaml`](../config.example.yaml); the schema is [`config-schema.json`](../../config-schema.json).

## Validate and run

```bash
./llama-swap -config config.yaml -validate
./llama-swap -config config.yaml -listen 127.0.0.1:8080
```

`-config` and/or `-config-dir` is required. `-version` prints build metadata. TLS requires both `-tls-cert-file` and `-tls-key-file`; the default listener is `:8080` without TLS and `:8443` with TLS.

## Configuration behavior

- `internal/config/load.go` substitutes environment macros, applies defaults, validates values, and normalizes routing.
- `watch-config` enables reload behavior using [`internal/watcher`](../../internal/watcher).
- `store.path` selects persistent SQLite; an empty path uses an in-memory store.

For endpoint details see [api.md](api.md), for internals see
[architecture.md](architecture.md), and for the target deployment see
[native Windows setup](../setup/windows-native.md).
