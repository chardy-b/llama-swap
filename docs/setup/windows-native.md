# Native Windows setup

This guide installs a private llama.cpp inference service on Windows, managed by
llama-swap and published only to the Tailscale network.

> [!IMPORTANT]
> The current fork adds documentation and the Gaming Mode design only. The
> persisted 1–4 hour Gaming Mode is not implemented yet. Until it lands, use
> llama-swap's existing **Unload all** action before gaming and stop
> `llama-swap.exe` if you need a hard guarantee that a client cannot reload a
> model.

## Target layout

```text
C:\LocalAI\
├── bin\                 # llama-server.exe and CUDA DLLs
├── config\config.yaml  # model and API configuration
├── data\                # logs/state later
└── scripts\             # local launch scripts
D:\Models\               # GGUF files; adjust to your actual drive
```

The service binds to `127.0.0.1:8080`. Tailscale Serve publishes that local
listener to authenticated tailnet devices over HTTPS. Do not bind llama-swap to
`0.0.0.0`, and do not use Tailscale Funnel.

## Phase 1: collect the machine profile

Open **PowerShell** on the Windows PC. Administrator rights are not needed.
Clone the fork and run the checked-in preflight script:

```powershell
git clone https://github.com/chardy-b/llama-swap.git C:\LocalAI\llama-swap
Set-Location C:\LocalAI\llama-swap
git switch wil-191-initialize-fork
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\preflight.ps1
```

If Git is not installed:

```powershell
winget install --exact --id Git.Git
```

Close and reopen PowerShell after installing Git. The preflight prints only
non-secret machine facts: Windows version, architecture, RAM, free disk,
NVIDIA GPU/driver/CUDA compatibility, Tailscale identity, and installed command
paths. Share that output before choosing a llama.cpp backend or model.

## Phase 2: install Tailscale and llama-swap

Skip either command if the preflight reports it is already installed:

```powershell
winget install --exact --id Tailscale.Tailscale
winget install --exact --id mostlygeek.llama-swap
```

The WinGet llama-swap package is maintained by a community contributor. The
upstream project also publishes an official Windows archive on its Releases
page. During the Gaming Mode implementation, the upstream binary is suitable
for baseline setup; later replace it with a Windows build from this fork.

Confirm both commands:

```powershell
tailscale version
llama-swap -version
```

Sign in to Tailscale if the PC is not already connected. This machine is
currently visible in the tailnet as `desktop-q0s7jb6` (`100.109.130.89`).

## Phase 3: install the correct llama.cpp build

### NVIDIA GPU

Use the official Windows x64 CUDA release from
[llama.cpp Releases](https://github.com/ggml-org/llama.cpp/releases). Download
both archives with matching release and CUDA versions:

- `llama-<build>-bin-win-cuda-12.4-x64.zip`
- `cudart-llama-bin-win-cuda-12.4-x64.zip`

CUDA 13 is also available, but only choose it after the preflight confirms a
compatible NVIDIA driver. CUDA 12.4 is the conservative default for an RTX
30-series machine.

Extract both archives into the same directory:

```text
C:\LocalAI\bin
```

Then verify:

```powershell
& C:\LocalAI\bin\llama-server.exe --version
& C:\LocalAI\bin\llama-bench.exe --help
```

Do not install the WinGet `ggml.llamacpp` package when CUDA performance is the
goal: its published portable package has historically used the Vulkan build.

### Non-NVIDIA GPU

Stop after the preflight. Select the official Vulkan, ROCm, SYCL, or CPU archive
that matches the detected hardware; do not mix backend DLLs from different
release builds.

## Phase 4: place one GGUF model

Start with one known-good instruct model. Put the complete `.gguf` file under
`D:\Models`, or replace that path with the drive shown by the preflight.

Before continuing, record its exact path:

```powershell
Get-ChildItem D:\Models\*.gguf | Select-Object FullName, Length
```

A quantization choice depends on GPU VRAM and desired context length. As a safe
starting rule, use `Q4_K_M`; prefer `Q5_K_M` or `Q6_K` when the preflight shows
enough free VRAM.

## Phase 5: create a local configuration

Create `C:\LocalAI\config\config.yaml`:

```yaml
healthCheckTimeout: 300
unloadTimeout: 30
globalTTL: 900
logLevel: info

apiKeys:
  - "${env.LLAMA_SWAP_KEY}"

models:
  local-chat:
    cmd: >-
      "C:\LocalAI\bin\llama-server.exe"
      --host 127.0.0.1
      --port ${PORT}
      --model "D:\Models\REPLACE_WITH_MODEL.gguf"
      --ctx-size 16384
      --n-gpu-layers 999
    ttl: 900
    capabilities:
      tools: true
```

Replace only the model path first. Keep `${PORT}` unchanged; llama-swap assigns
it. `ttl: 900` unloads the model after 15 minutes without requests. This is not
Gaming Mode because a new request can load it again.

### Create the API key locally

Do not put the key in Git, this document, chat, or a command-line argument.
Generate it inside PowerShell for the current process:

```powershell
$bytes = New-Object byte[] 48
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()
$env:LLAMA_SWAP_KEY = 'sk-' + [Convert]::ToBase64String($bytes)
```

Save it in your password manager before closing PowerShell. Later, use Windows
Credential Manager or a same-user DPAPI-protected launcher for unattended
startup. Do not store it literally in `config.yaml`.

## Phase 6: validate and start locally

```powershell
llama-swap -config C:\LocalAI\config\config.yaml -validate
llama-swap -config C:\LocalAI\config\config.yaml -listen 127.0.0.1:8080
```

Leave that PowerShell window open. In a second PowerShell window, set the same
key locally and test management access:

```powershell
$headers = @{ Authorization = "Bearer $env:LLAMA_SWAP_KEY" }
Invoke-RestMethod http://127.0.0.1:8080/v1/models -Headers $headers
```

Test inference; the first request starts `llama-server.exe` and may take time:

```powershell
$body = @{
  model = 'local-chat'
  messages = @(@{ role = 'user'; content = 'Reply with exactly: ready' })
  max_tokens = 16
} | ConvertTo-Json -Depth 5

Invoke-RestMethod `
  http://127.0.0.1:8080/v1/chat/completions `
  -Method Post `
  -Headers $headers `
  -ContentType 'application/json' `
  -Body $body
```

Open `http://127.0.0.1:8080` for the web UI.

## Phase 7: publish only through Tailscale

Once localhost works, run:

```powershell
tailscale serve --bg http://127.0.0.1:8080
tailscale serve status
```

Tailscale prints the HTTPS URL. Test that URL from another tailnet device. Keep
the llama-swap API key enabled even though Tailscale already controls network
access.

Do **not** run `tailscale funnel`. Do **not** add a public router port-forward.
Restrict the node/service with tailnet grants or ACLs if devices other than
Richard's should not reach it.

## Existing manual GPU release

Until Gaming Mode is implemented:

1. In the Models page, select **Unload all**.
2. Confirm `llama-server.exe` stopped in Task Manager or with:

   ```powershell
   Get-Process llama-server -ErrorAction SilentlyContinue
   nvidia-smi
   ```

3. For a hard no-reload window, stop `llama-swap.exe` too. Restart it when
   inference should be available again.

The management API can also unload all models:

```powershell
Invoke-RestMethod `
  http://127.0.0.1:8080/api/models/unload `
  -Method Post `
  -Headers $headers
```

## Do not automate startup yet

First complete one local inference request, one tailnet request, one unload, and
one clean restart. After those pass, add a same-user Scheduled Task and a
DPAPI-protected key launcher. This prevents a broken configuration from becoming
a persistent startup loop.

## Troubleshooting

### `llama-server` is not found

Use the absolute executable path in `cmd` and verify it directly:

```powershell
Test-Path C:\LocalAI\bin\llama-server.exe
```

### Model starts but llama-swap times out

Keep `--port ${PORT}` in the command and leave `proxy` unset. Confirm
`http://127.0.0.1:<assigned-port>/health` appears in llama-swap logs.

### CUDA DLL or driver error

Verify that the llama.cpp and CUDA-runtime archives came from the same release
and backend version. Run `nvidia-smi` and compare the driver's reported CUDA
compatibility with the downloaded archive.

### Tailnet URL does not work

```powershell
tailscale status
tailscale serve status
Test-NetConnection 127.0.0.1 -Port 8080
```

The application must remain bound to localhost; fix Tailscale Serve rather than
opening Windows Firewall to the public network.

## Next documents

- [Code wiki getting started](../wiki/getting-started.md)
- [Architecture](../wiki/architecture.md)
- [Gaming Mode design](../design/gaming-mode.md)
- [Gaming Mode implementation plan](../plans/gaming-mode-mvp.md)
- [Upstream API-key guidance](../kb/guides/api-integration/api-keys-and-auth.md)
- [Upstream TTL and unload guidance](../kb/guides/model-runtime/ttl-and-unloading.md)
