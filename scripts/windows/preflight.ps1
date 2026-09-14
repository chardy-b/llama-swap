[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

function Write-Section {
    param([Parameter(Mandatory = $true)][string]$Name)
    Write-Host ""
    Write-Host "=== $Name ==="
}

function Show-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Write-Host "${Name}: not found"
        return
    }
    Write-Host "${Name}: $($command.Source)"
}

Write-Host 'Local Llama Server Windows preflight'
Write-Host 'This report contains no API keys or stored credentials.'
Write-Warning 'It does contain operational details such as host and Tailscale identity, IP addresses, hardware, paths, and process IDs. Review and redact it before sharing outside a trusted support channel.'

Write-Section 'Windows'
$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
[pscustomobject]@{
    ComputerName = $env:COMPUTERNAME
    Caption = $os.Caption
    Version = $os.Version
    BuildNumber = $os.BuildNumber
    Architecture = $os.OSArchitecture
    PowerShell = $PSVersionTable.PSVersion.ToString()
    TotalRAMGiB = [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
} | Format-List

Write-Section 'Fixed disks'
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
    Select-Object DeviceID,
        @{Name = 'SizeGiB'; Expression = { [math]::Round($_.Size / 1GB, 1) }},
        @{Name = 'FreeGiB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 1) }} |
    Format-Table -AutoSize

Write-Section 'Display adapters'
Get-CimInstance Win32_VideoController |
    Select-Object Name, DriverVersion,
        @{Name = 'AdapterRAMGiB'; Expression = {
            if ($null -eq $_.AdapterRAM) { $null } else { [math]::Round($_.AdapterRAM / 1GB, 1) }
        }} |
    Format-Table -AutoSize

Write-Section 'NVIDIA runtime'
$nvidia = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($null -eq $nvidia) {
    Write-Host 'nvidia-smi: not found'
} else {
    & $nvidia.Source --query-gpu=index,name,driver_version,memory.total,memory.free --format=csv,noheader
    Write-Host ''
    & $nvidia.Source | Select-Object -First 4
}

Write-Section 'Required commands'
@('git', 'winget', 'tailscale', 'llama-swap', 'llama-server') | ForEach-Object {
    Show-Command -Name $_
}

Write-Section 'Tailscale'
$tailscale = Get-Command tailscale -ErrorAction SilentlyContinue
if ($null -eq $tailscale) {
    Write-Host 'Tailscale is not installed or not on PATH.'
} else {
    & $tailscale.Source version
    Write-Host ''
    & $tailscale.Source ip -4
    & $tailscale.Source status --self
    Write-Host ''
    & $tailscale.Source serve status
}

Write-Section 'Reserved local ports'
foreach ($port in @(8080, 5800, 5801, 5802)) {
    $listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
    if ($null -eq $listener) {
        Write-Host "${port}: available"
    } else {
        $owners = $listener | Select-Object -ExpandProperty OwningProcess -Unique
        Write-Host "${port}: in use by PID $($owners -join ',')"
    }
}

Write-Section 'Result'
Write-Host 'Preflight complete. Review and redact operational details before sharing the output to select the CUDA build, model quant, context size, and model directory.'
