$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$apiPort = if ($env:PINSHOP_API_PORT) { $env:PINSHOP_API_PORT } else { '8080' }
$adb = Get-Command adb -ErrorAction SilentlyContinue
$adbPath = if ($adb) { $adb.Source } else { $null }
if (-not $adb) {
  $sdkAdb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
  if (Test-Path $sdkAdb) {
    $adbPath = $sdkAdb
  }
}

$useAdbReverse = $false
if ($adbPath -and -not $env:PINSHOP_USE_LAN) {
  $devices = & $adbPath devices | Select-String -Pattern "`tdevice$"
  if ($devices) {
    & $adbPath reverse "tcp:$apiPort" "tcp:$apiPort" | Out-Null
    & $adbPath reverse 'tcp:9000' 'tcp:9000' | Out-Null
    $useAdbReverse = $true
  }
}

if ($useAdbReverse) {
  $apiUrl = "http://127.0.0.1:${apiPort}"
  Write-Host "Using ADB reverse: device tcp:$apiPort -> host tcp:$apiPort"
} else {
  $ipConfig = Get-NetIPConfiguration |
    Where-Object {
      $_.IPv4Address -and
      $_.NetAdapter.Status -eq 'Up' -and
      $_.InterfaceAlias -notmatch 'VPN|Virtual|Loopback|Docker|vEthernet'
    } |
    Sort-Object { if ($_.IPv4DefaultGateway) { 0 } else { 1 } } |
    Select-Object -First 1

  if (-not $ipConfig) {
    throw 'No active LAN/Wi-Fi IPv4 address found. Connect this PC and phone to the same network.'
  }

  $hostIp = $ipConfig.IPv4Address.IPAddress
  $apiUrl = "http://${hostIp}:${apiPort}"
}

Write-Host "Using API_URL=$apiUrl"

try {
  $health = Invoke-WebRequest -Uri "$apiUrl/health" -UseBasicParsing -TimeoutSec 5
  Write-Host "API health: $($health.StatusCode) $($health.Content)"
} catch {
  Write-Warning "API did not answer at $apiUrl/health from Windows. Check Docker and Windows Firewall."
}

Push-Location $repoRoot
try {
  $flutterArgs = @('run', "--dart-define=API_URL=$apiUrl")
  if (-not $useAdbReverse) {
    $flutterArgs += '--dart-define=ENABLE_DEV_IMAGE_REWRITE=true'
  }
  & flutter @flutterArgs
} finally {
  Pop-Location
}
