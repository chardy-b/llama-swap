# Gaming Mode design

**Status:** Approved by the user for planning

**Source baseline:** `21bc145a6fa6198c4d856fbb0830845c472b0ae4`

**Decision owner:** Richard Li

## Outcome

Let Richard temporarily reserve the Windows GPU for gaming without shutting down
the lightweight llama-swap UI and supervisor. A remote client behind Tailscale
can see the deadline but cannot wake a local model before it expires.

## V1 contract

- Native Windows amd64 is the first supported deployment. Linux and WSL remain
  compatible.
- The UI offers 1, 2, 3, and 4 hour buttons, a countdown, and **End now**.
- The authenticated management API exposes:
  - `GET /api/gaming-mode`
  - `PUT /api/gaming-mode` with `{ "duration_minutes": 60|120|180|240 }`
  - `DELETE /api/gaming-mode`
- The server persists an absolute UTC deadline and returns an RFC3339 timestamp.
  UI presentation uses the browser's local time.
- Activation closes the local request gate before unloading all local models.
- While active, local inference, local `/upstream/<model>` passthrough, and
  explicit local load operations return HTTP `503 Service Unavailable`, a
  `Retry-After` header, and a structured `gaming_mode` error.
- Management/status/UI endpoints remain available. Peer-only model requests are
  not blocked because they do not consume this host's GPU.
- When the deadline expires, requests are allowed again, but no model preloads.
- Early cancellation is idempotent. Setting a new duration replaces the prior
  deadline.

Example status:

```json
{
  "active": true,
  "until": "2026-09-14T01:30:00Z",
  "remaining_seconds": 6342,
  "state": "active"
}
```

Example blocked response:

```json
{
  "error": {
    "type": "gaming_mode",
    "message": "Local inference is temporarily disabled.",
    "retry_after_seconds": 6342,
    "until": "2026-09-14T01:30:00Z"
  }
}
```

## Architecture

Add a concurrency-safe `internal/gamingmode` service with a clock abstraction
and persistence interface. Its snapshot is the single authority for gate
checks and API/UI state. Use a small atomically replaced JSON state file in the
OS user config directory by default, with an explicit startup flag to override
its location for services and tests. An expired or absent deadline reads as
inactive; malformed state must fail startup rather than silently bypass a
requested lockout.

`internal/server` owns route classification. It checks the Gaming Mode gate only
after resolving whether a request targets a local model. This preserves peer
forwarding. A successful `PUT` first persists/activates the deadline, then calls
`LocalRouter.Unload(0)`, then returns success. Concurrent local requests arriving
after activation get `503`; router unload drains or cancels already queued local
work according to existing router behavior.

The UI extends the models dashboard because it already owns manual model load,
unload, profiles, and selectors. The SSE channel carries Gaming Mode state
changes so multiple open tabs converge; a periodic local countdown does not
need a server request each second.

## Security and deployment

- Bind llama-swap to localhost.
- Publish with Tailscale Serve or the repository's Tailcat listener, not Funnel.
- Require llama-swap API keys as defense in depth.
- Apply Tailscale ACLs/grants to Richard's identity or named devices.
- Store no API key in the persisted Gaming Mode state.

## Non-goals

- Suspending the Windows host, stopping Tailscale, or killing llama-swap itself.
- Public Internet exposure.
- Automatic game-process detection.
- Arbitrary durations in the v1 UI or API.
- Editing model definitions or downloading models from the UI.
- Changing llama.cpp inference internals.

## Success criteria

1. Selecting 1–4 hours activates a persisted deadline and unloads all local
   model processes.
2. No allowed remote request can reload a local model while the gate is active.
3. Restart and Windows sleep do not shorten the deadline.
4. Expiry and **End now** reopen requests without preloading a model.
5. Peer requests, UI, status, and authenticated management remain usable.
6. Windows build, focused race tests, server tests, and UI tests pass.
7. A localhost-only Tailscale deployment runbook is verified on the target PC.

## Key risks

- **Activation race:** prevented by persisting and closing the gate before
  unload.
- **Clock changes:** persist an absolute UTC deadline and test clock jumps.
- **State corruption:** fail closed at startup and provide a clear recovery
  message/path.
- **Route gaps:** enumerate every local-load path in tests, including upstream
  passthrough and OpenAI-compatible aliases/selectors.
- **Upstream drift:** isolate fork-specific policy so regular upstream merges
  stay small.
