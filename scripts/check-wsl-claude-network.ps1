param(
  [string]$Distro = "",
  [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = "Stop"

function Invoke-Wsl {
  param([string]$Command)
  if ($Distro) {
    & wsl.exe -d $Distro -- bash -lc $Command
  } else {
    & wsl.exe -- bash -lc $Command
  }
}

Write-Output "== Windows proxy-related environment =="
$proxyNames = @("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "http_proxy", "https_proxy", "all_proxy")
foreach ($name in $proxyNames) {
  $value = [Environment]::GetEnvironmentVariable($name, "User")
  if (-not $value) {
    $value = [Environment]::GetEnvironmentVariable($name, "Machine")
  }
  if ($value) {
    Write-Output "$name=<set length=$($value.Length)>"
  }
}

Write-Output ""
Write-Output "== Windows .wslconfig =="
$wslConfig = Join-Path $env:USERPROFILE ".wslconfig"
if (Test-Path -LiteralPath $wslConfig) {
  Get-Content -LiteralPath $wslConfig
} else {
  Write-Output "<missing>"
}

Write-Output ""
Write-Output "== Windows proxy listener hints =="
netstat -ano | Select-String "10811|7890|7897|10809" | Select-Object -First 20

Write-Output ""
Write-Output "== WSL proxy environment =="
Invoke-Wsl "env | grep -i proxy || true"

Write-Output ""
Write-Output "== WSL HTTPS probes =="
$urls = @(
  "https://github.com",
  "https://www.google.com",
  "https://sub.flash-l.cloud"
)
foreach ($url in $urls) {
  Write-Output "-- $url"
  Invoke-Wsl "curl -I --max-time $TimeoutSeconds '$url' 2>&1 | sed -n '1,8p'"
}
