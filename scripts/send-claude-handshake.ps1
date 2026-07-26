param(
  [string]$ProjectId = "cailiao",
  [int]$WaitSeconds = 45,
  [switch]$UseUiA
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Task = Join-Path $env:TEMP ("codex-claude-handshake-" + [guid]::NewGuid().ToString("N") + ".md")
$TaskId = "codex-claude-handshake-" + (Get-Date -Format "yyyyMMdd-HHmmss")

@"
# CODEX_TO_CLAUDE_LATEST

Task ID: $TaskId

This is a handshake only.
Do not modify any project repository.
Create or overwrite exactly this file:
/home/kiro/kiro-work/work/CLAUDE_ACK_FROM_CODEX.txt

Content must be exactly one line:
ACK $TaskId

After writing it, stop and wait for the next task.
"@ | Set-Content -LiteralPath $Task -Encoding UTF8

try {
  $Config = Get-Content (Join-Path $Root "control\projects.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  $Project = $Config.projects | Where-Object { $_.id -eq $ProjectId } | Select-Object -First 1
  if (-not $Project) {
    throw "Project not found: $ProjectId"
  }
  $AckPath = "$($Project.wsl_workdir)/CLAUDE_ACK_FROM_CODEX.txt"
  & wsl.exe -d $Project.wsl_distro -- bash -lc "rm -f '$AckPath'"
  $Result = & (Join-Path $Root "scripts\send-claude-task.ps1") -ProjectId $ProjectId -TaskPath $Task -WaitSeconds $WaitSeconds -UseUiA:$UseUiA
  $Expected = "ACK $TaskId"
  $Ack = ""
  $Deadline = (Get-Date).AddSeconds($WaitSeconds)
  while ((Get-Date) -lt $Deadline) {
    Start-Sleep -Seconds 3
    $Ack = (& wsl.exe -d $Project.wsl_distro -- bash -lc "cat '$AckPath' 2>/dev/null || true") -join "`n"
    if ($Ack -match [regex]::Escape($Expected)) {
      break
    }
  }
  [ordered]@{
    task_id = $TaskId
    result = ($Result | Out-String).Trim()
    ack = ($Ack | Out-String).Trim()
    ok = (($Ack | Out-String) -match [regex]::Escape($Expected))
  } | ConvertTo-Json -Depth 4
} finally {
  Remove-Item -LiteralPath $Task -Force -ErrorAction SilentlyContinue
}
