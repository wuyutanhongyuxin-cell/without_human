param(
  [string]$ProjectId = "cailiao"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ProjectsPath = Join-Path $Root "control\projects.json"
$Config = Get-Content $ProjectsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Project = $Config.projects | Where-Object { $_.id -eq $ProjectId } | Select-Object -First 1
if (-not $Project) {
  throw "Project not found: $ProjectId"
}

function Invoke-WslText {
  param([string]$Command)
  $Command | & wsl.exe -d $Project.wsl_distro -- bash
}

$Status = [ordered]@{
  project = $Project.id
  distro = $Project.wsl_distro
  task_file = $Project.task_file
  report_file = $Project.report_file
  wsl_list_visible = $null
  claude_pid = $null
  claude_tty = $null
  tty_writable = $false
  ack_file = "$($Project.wsl_workdir)/CLAUDE_ACK_FROM_CODEX.txt"
  repo_status = $null
}

try {
  $Status.wsl_list_visible = (& wsl.exe -l -v) -join "`n"
} catch {
  $Status.wsl_list_visible = "wsl -l -v failed: $($_.Exception.Message)"
}

$ProbeCommand = @'
set -e
pid=""
comm=$(cat /proc/9/comm 2>/dev/null || true)
if [ x$comm = xclaude ]; then
  pid=9
fi
if [ -n "$pid" ]; then
  tty=$(readlink /proc/$pid/fd/0 2>/dev/null || true)
  writable=no
  [ -n "$tty" ] && [ -w "$tty" ] && writable=yes
  printf 'PID=%s\nTTY=%s\nWRITABLE=%s\n' "$pid" "$tty" "$writable"
else
  printf 'PID=\nTTY=\nWRITABLE=no\n'
fi
cd '__WSL_REPO__' 2>/dev/null && { printf 'REPO_STATUS_BEGIN\n'; git status --short; printf 'REPO_STATUS_END\n'; } || true
'@
$ProbeCommand = $ProbeCommand.Replace("__WSL_REPO__", $Project.wsl_repo)
$Probe = Invoke-WslText $ProbeCommand

foreach ($Line in $Probe) {
  if ($Line -like "PID=*") { $Status.claude_pid = $Line.Substring(4) }
  elseif ($Line -like "TTY=*") { $Status.claude_tty = $Line.Substring(4) }
  elseif ($Line -like "WRITABLE=*") { $Status.tty_writable = ($Line.Substring(9) -eq "yes") }
}
$RepoLines = @()
$InRepo = $false
foreach ($Line in $Probe) {
  if ($Line -eq "REPO_STATUS_BEGIN") { $InRepo = $true; continue }
  if ($Line -eq "REPO_STATUS_END") { $InRepo = $false; continue }
  if ($InRepo) { $RepoLines += $Line }
}
$Status.repo_status = $RepoLines

$Status | ConvertTo-Json -Depth 4
