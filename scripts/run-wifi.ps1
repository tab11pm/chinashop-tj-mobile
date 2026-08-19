param(
  [string] $Port = '',
  [string] $DeviceId = ''
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
if (-not $Port) {
  $Port = if ($env:PINSHOP_API_PORT) { $env:PINSHOP_API_PORT } else { '8080' }
}

function Get-LanIpConfig {
  $configs = Get-NetIPConfiguration |
    Where-Object {
      $_.IPv4Address -and
      $_.NetAdapter.Status -eq 'Up' -and
      $_.InterfaceAlias -notmatch 'VPN|Virtual|Loopback|Docker|vEthernet|Bluetooth'
    } |
    Sort-Object `
      @{ Expression = { if ($_.NetAdapter.InterfaceDescription -match 'Wi-?Fi|Wireless|802\.11|AX|AC') { 0 } else { 1 } } },
      @{ Expression = { if ($_.IPv4DefaultGateway) { 0 } else { 1 } } }

  return $configs | Select-Object -First 1
}

$ipConfig = Get-LanIpConfig
if (-not $ipConfig) {
  throw 'No active Wi-Fi/LAN IPv4 address found. Connect this PC to the same Wi-Fi/LAN as the phone.'
}

$hostIp = $ipConfig.IPv4Address.IPAddress
$apiUrl = "http://${hostIp}:${Port}"

Write-Host "Interface: $($ipConfig.InterfaceAlias)"
Write-Host "Host IP:   $hostIp"
Write-Host "API_URL:   $apiUrl"

try {
  $health = Invoke-WebRequest -Uri "$apiUrl/health" -UseBasicParsing -TimeoutSec 5
  Write-Host "API health: $($health.StatusCode) $($health.Content)"
} catch {
  Write-Warning "API did not answer at $apiUrl/health from Windows."
  Write-Warning 'Check: docker compose is up, Windows Firewall allows TCP 8080, and VPN split-tunnel does not capture the local subnet.'
}

$flutterArgs = @(
  'run',
  "--dart-define=API_URL=$apiUrl",
  '--dart-define=ENABLE_DEV_IMAGE_REWRITE=true'
)
if ($DeviceId) {
  $flutterArgs += @('-d', $DeviceId)
}

Push-Location $repoRoot
try {
  Write-Host "Running: flutter $($flutterArgs -join ' ')"
  & flutter @flutterArgs
} finally {
  Pop-Location
}
