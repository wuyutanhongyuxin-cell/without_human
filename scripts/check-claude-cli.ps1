param(
  [switch]$LiveProbe
)

$ErrorActionPreference = "Stop"

$Status = [ordered]@{
  claude_command = $null
  claude_path = $null
  version = $null
  help_supports_print = $false
  help_supports_background = $false
  doctor_summary = $null
  candidate_for_background_dispatch = $false
  live_probe = [ordered]@{
    requested = [bool]$LiveProbe
    ok = $false
    exit_code = $null
    error = $null
    output_hint = $null
  }
  usable_for_background_dispatch = $false
}

$Command = Get-Command claude -ErrorAction SilentlyContinue
if (-not $Command) {
  $Status.live_probe.error = "claude command not found"
  $Status | ConvertTo-Json -Depth 5
  exit 1
}

$Status.claude_command = $Command.Name
$Status.claude_path = $Command.Source

$Version = (& claude --version 2>&1) -join "`n"
$Status.version = $Version.Trim()

$Help = (& claude --help 2>&1) -join "`n"
$Status.help_supports_print = ($Help -match '--print' -and $Help -match 'non-interactive')
$Status.help_supports_background = ($Help -match '--background')
$Status.candidate_for_background_dispatch = $Status.help_supports_print

try {
  $Doctor = (& claude doctor 2>&1) -join "`n"
  $Status.doctor_summary = (($Doctor -split "`r?`n") | Where-Object {
    $_ -match 'Running:|Path:|No installation issues|Not signed in|OAuth|subscription|auth'
  }) -join "`n"
} catch {
  $Status.doctor_summary = "claude doctor failed: $($_.Exception.Message)"
}

if ($LiveProbe) {
  $ProbeOutput = (& claude -p "Return exactly CLI_OK." --output-format json --tools default 2>&1) -join "`n"
  $Status.live_probe.exit_code = $LASTEXITCODE
  $Status.live_probe.output_hint = ($ProbeOutput.Substring(0, [Math]::Min(500, $ProbeOutput.Length))).Trim()
  if ($LASTEXITCODE -eq 0 -and $ProbeOutput -match 'CLI_OK') {
    $Status.live_probe.ok = $true
  } else {
    $Status.live_probe.error = "live probe failed"
    if ($ProbeOutput -match 'Failed to authenticate|OAuth session expired|not signed in|authentication_failed') {
      $Status.live_probe.error = "authentication failed or expired"
      $Status.live_probe.output_hint = "Failed to authenticate: OAuth session expired or account is not signed in."
    }
  }
}

$Status.usable_for_background_dispatch = ($Status.help_supports_print -and $LiveProbe -and $Status.live_probe.ok)

$Status | ConvertTo-Json -Depth 5
if ($LiveProbe -and -not $Status.live_probe.ok) {
  exit 2
}
