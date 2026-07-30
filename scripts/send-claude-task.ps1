param(
  [Parameter(Mandatory=$true)][string]$TaskPath,
  [string]$ProjectId = "cailiao",
  [int]$WaitSeconds = 60,
  [int]$PollSeconds = 2,
  [switch]$UseUiA
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ProjectsPath = Join-Path $Root "control\projects.json"
$Config = Get-Content $ProjectsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Project = $Config.projects | Where-Object { $_.id -eq $ProjectId } | Select-Object -First 1
if (-not $Project) {
  throw "Project not found: $ProjectId"
}
if (-not (Test-Path $TaskPath)) {
  throw "Task file not found: $TaskPath"
}

$TaskText = Get-Content $TaskPath -Raw -Encoding UTF8
$TaskId = $null
if ($TaskText -match '(?m)^\s*#?\s*Task ID:\s*([A-Za-z0-9_.:-]+)\s*$') {
  $TaskId = $Matches[1]
} else {
  $TaskId = [System.IO.Path]::GetFileNameWithoutExtension($TaskPath)
}
$AckFile = "$($Project.wsl_workdir)/CLAUDE_ACK_FROM_CODEX.txt"
$ReportMtimeBeforeLines = & wsl.exe -d $Project.wsl_distro -- bash -lc "stat -c %Y '$($Project.report_file)' 2>/dev/null || echo 0"
$ReportMtimeBefore = ($ReportMtimeBeforeLines | Where-Object { $_ -match '^\d+$' } | Select-Object -Last 1)
if (-not $ReportMtimeBefore) {
  $ReportMtimeBefore = "0"
}
$TaskText | & wsl.exe -d $Project.wsl_distro -- bash -lc "cat > '$($Project.task_file)'"
if ($LASTEXITCODE -ne 0) {
  throw "Failed to write WSL task file: $($Project.task_file)"
}

$ShortCommand = "Task ID: $TaskId. Read $($Project.task_file) now and execute it exactly. Write report to $($Project.report_file) with this Task ID."

if ($UseUiA) {
  Add-Type -AssemblyName UIAutomationClient
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@
  $RootElement = [System.Windows.Automation.AutomationElement]::RootElement
  $WindowCondition = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Window)
  $Windows = $RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, $WindowCondition)
  $ClaudeWindow = $null
  $PreferredPatterns = @("codex_to_claude", "claude agents", "Execute Codex-to-Claude", "Claude Code")
  foreach ($Window in $Windows) {
    $Name = $Window.Current.Name
    foreach ($Pattern in $PreferredPatterns) {
      if ($Name -match [regex]::Escape($Pattern)) {
        $ClaudeWindow = $Window
        break
      }
    }
    if ($ClaudeWindow) { break }
  }
  if (-not $ClaudeWindow) {
    throw "Claude window not found. Use scripts/check-claude-channel.ps1 and verify the Claude CLI session is open."
  }
  [Win32]::SetForegroundWindow([intptr]$ClaudeWindow.Current.NativeWindowHandle) | Out-Null
  Start-Sleep -Milliseconds 500
  [System.Windows.Forms.Clipboard]::SetText($ShortCommand)
  [System.Windows.Forms.SendKeys]::SendWait("^v")
  Start-Sleep -Milliseconds 150
  [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
} else {
  $ProbeCommand = 'comm=$(cat /proc/9/comm 2>/dev/null || true); if [ x$comm = xclaude ]; then readlink /proc/9/fd/0; fi'
  $Probe = & wsl.exe -d $Project.wsl_distro -- bash -lc $ProbeCommand
  $Tty = ($Probe | Select-Object -First 1)
  if (-not $Tty) {
    throw "Claude TTY not found. Retry with -UseUiA after opening the Claude CLI session."
  }
  & wsl.exe -d $Project.wsl_distro -- bash -lc "printf '%s\r' '$ShortCommand' > '$Tty'"
}

$Deadline = (Get-Date).AddSeconds($WaitSeconds)
$LastReport = ""
$ObservedKind = "none"
while ((Get-Date) -lt $Deadline) {
  Start-Sleep -Seconds $PollSeconds
  $ReportCmd = @'
mtime=$(stat -c %Y '__REPORT__' 2>/dev/null || echo 0)
case "$mtime" in ''|*[!0-9]*) mtime=0;; esac
if [ "$mtime" -gt '__BEFORE__' ] && grep -q '__TASKID__' '__REPORT__' 2>/dev/null; then
  grep -m1 -E 'Report: __TASKID__|Task ID: __TASKID__|Status|Summary' '__REPORT__' || true
fi
'@
  $ReportCmd = $ReportCmd.Replace("__REPORT__", $Project.report_file).Replace("__BEFORE__", $ReportMtimeBefore).Replace("__TASKID__", $TaskId)
  $Report = & wsl.exe -d $Project.wsl_distro -- bash -lc $ReportCmd
  $Ack = & wsl.exe -d $Project.wsl_distro -- bash -lc "if [ -f '$AckFile' ] && grep -q '$TaskId' '$AckFile' 2>/dev/null; then cat '$AckFile'; fi"
  $Diff = & wsl.exe -d $Project.wsl_distro -- bash -lc "cd '$($Project.wsl_repo)' && git status --short"
  $LastReport = (($Report + $Ack + $Diff) -join "`n")
  if ($Report) { $ObservedKind = "matching_report"; break }
  if ($Ack) { $ObservedKind = "matching_ack"; break }
  if ($Diff) {
    $ObservedKind = "wsl_diff"
    break
  }
}

[ordered]@{
  project = $Project.id
  task_id = $TaskId
  sent = $true
  used_uia = [bool]$UseUiA
  waited_seconds = $WaitSeconds
  poll_seconds = $PollSeconds
  observed_kind = $ObservedKind
  observed = $LastReport
} | ConvertTo-Json -Depth 4
