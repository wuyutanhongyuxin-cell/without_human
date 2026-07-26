param(
  [Parameter(Mandatory=$true)][string]$TaskPath,
  [string]$ProjectId = "cailiao",
  [int]$WaitSeconds = 60,
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
$TaskText | & wsl.exe -d $Project.wsl_distro -- bash -lc "cat > '$($Project.task_file)'"
if ($LASTEXITCODE -ne 0) {
  throw "Failed to write WSL task file: $($Project.task_file)"
}

$ShortCommand = "Read CODEX_TO_CLAUDE_LATEST.md now and execute it exactly. Write the requested report or ack file when done."

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
  foreach ($Window in $Windows) {
    $Name = $Window.Current.Name
    if ($Name -match "codex_to_claude|claude agents|Execute Codex-to-Claude|Claude Code") {
      $ClaudeWindow = $Window
      break
    }
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
while ((Get-Date) -lt $Deadline) {
  Start-Sleep -Seconds 5
  $Report = & wsl.exe -d $Project.wsl_distro -- bash -lc "if [ -f '$($Project.report_file)' ]; then grep -m1 -E 'Task ID|Status|Summary' '$($Project.report_file)' || true; fi"
  $Ack = & wsl.exe -d $Project.wsl_distro -- bash -lc "if [ -f '$($Project.wsl_workdir)/CLAUDE_ACK_FROM_CODEX.txt' ]; then cat '$($Project.wsl_workdir)/CLAUDE_ACK_FROM_CODEX.txt'; fi"
  $Diff = & wsl.exe -d $Project.wsl_distro -- bash -lc "cd '$($Project.wsl_repo)' && git status --short"
  $LastReport = (($Report + $Ack + $Diff) -join "`n")
  if ($Report -or $Ack -or $Diff) {
    break
  }
}

[ordered]@{
  project = $Project.id
  sent = $true
  used_uia = [bool]$UseUiA
  waited_seconds = $WaitSeconds
  observed = $LastReport
} | ConvertTo-Json -Depth 4
