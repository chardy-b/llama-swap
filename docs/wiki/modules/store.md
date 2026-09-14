# Module: `store`

`internal/store` persists activity and token metrics in SQLite, with embedded Goose migrations.

## Key files

- [`store.go`](../../../internal/store/store.go) — database lifecycle, activity types, inserts, and queries.
Migration SQL is embedded by `store.go` from the module's migration resources.

## Public surface

`New(path)` opens a disk-backed or in-memory store; `Close` releases it; `InsertActivity` records a request; activity query/statistics methods return pages and aggregates. `ActivitySortColumn` whitelists sortable API keys before SQL construction.

## Behavior

Disk databases use WAL mode and the store limits SQLite to one open connection. Empty paths use `:memory:`. Migration files are embedded into the binary.
