# Module: `config`

`internal/config` turns YAML sources into the validated runtime model used by the server and routers.

## Key files

- [`load.go`](../../../internal/config/load.go) — reads, macro-expands, defaults, validates, and normalizes configuration.
- [`config.go`](../../../internal/config/config.go) — core configuration structs and YAML behavior.
- [`model_config.go`](../../../internal/config/model_config.go) — per-model settings and validation.
- [`matrix.go`](../../../internal/config/matrix.go) and [`peer.go`](../../../internal/config/peer.go) — routing-related configuration types.

## Public surface

`LoadConfigFromReader` and `LoadConfigSources` are the principal loaders. `Config` carries models, profiles, selectors, peers, routing, logging, storage, and process defaults. `ModelConfig` describes each upstream command, proxy, aliases, capabilities, filters, and lifecycle settings.

## Notable behavior

Environment and named macros are resolved before decoding. Health-check, ports, TTLs, performance, aliases, legacy routing fields, and API-facing defaults are normalized before callers receive `Config`.
