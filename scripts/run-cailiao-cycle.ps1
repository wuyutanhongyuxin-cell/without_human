param(
  [Parameter(Mandatory=$true)][string]$TaskPath,
  [string]$ProjectId = "cailiao",
  [int]$WaitSeconds = 900,
  [int]$PollSeconds = 5,
  [int]$GateTimeoutSeconds = 900,
  [string]$CommitMessage = "",
  [switch]$UseUiA,
  [switch]$SkipFullGate,
  [switch]$Push,
  [switch]$WatchCi,
  [switch]$SyncWsl,
  [switch]$DryRun
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

$Repo = $Project.windows_repo
if (-not (Test-Path $Repo)) {
  throw "Windows repo not found: $Repo"
}

$RunId = Get-Date -Format "yyyyMMdd-HHmmss"
$LogDir = Join-Path $Root "tmp\cycles"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogPath = Join-Path $LogDir "$ProjectId-cycle-$RunId.json"
$Events = @()

function Add-Event {
  param(
    [string]$Step,
    [string]$Status,
    $Data = $null
  )
  $script:Events += [ordered]@{
    ts = (Get-Date).ToString("o")
    step = $Step
    status = $Status
    data = $Data
  }
}

function Save-Log {
  param([string]$FinalStatus)
  [ordered]@{
    project = $Project.id
    run_id = $RunId
    final_status = $FinalStatus
    task_path = (Resolve-Path $TaskPath).Path
    repo = $Repo
    cli_session_to_session = -not [bool]$UseUiA
    used_uia = [bool]$UseUiA
    dry_run = [bool]$DryRun
    pushed = [bool]$Push
    events = $Events
  } | ConvertTo-Json -Depth 12 | Set-Content -Path $LogPath -Encoding UTF8
}

function Run-Checked {
  param(
    [string]$Step,
    [scriptblock]$Block
  )
  Add-Event $Step "started"
  try {
    $Data = & $Block
    Add-Event $Step "ok" $Data
    return $Data
  } catch {
    Add-Event $Step "failed" ([ordered]@{ error = $_.Exception.Message })
    Save-Log "failed"
    throw
  }
}

function Invoke-ProcessWithTimeout {
  param(
    [string]$FileName,
    [string[]]$Arguments,
    [string]$WorkingDirectory,
    [int]$TimeoutSeconds
  )
  $Psi = New-Object System.Diagnostics.ProcessStartInfo
  $Psi.FileName = $FileName
  foreach ($Arg in $Arguments) {
    [void]$Psi.ArgumentList.Add($Arg)
  }
  $Psi.WorkingDirectory = $WorkingDirectory
  $Psi.UseShellExecute = $false
  $Psi.RedirectStandardOutput = $true
  $Psi.RedirectStandardError = $true
  $Proc = [System.Diagnostics.Process]::Start($Psi)
  if (-not $Proc.WaitForExit($TimeoutSeconds * 1000)) {
    try { $Proc.Kill() } catch {}
    throw "$FileName timed out after $TimeoutSeconds seconds"
  }
  [ordered]@{
    exit_code = $Proc.ExitCode
    stdout = $Proc.StandardOutput.ReadToEnd()
    stderr = $Proc.StandardError.ReadToEnd()
  }
}

try {
  $Channel = Run-Checked "check_claude_channel" {
    $Args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "scripts\check-claude-channel.ps1"), "-ProjectId", $Project.id)
    Invoke-ProcessWithTimeout -FileName "powershell" -Arguments $Args -WorkingDirectory $Root -TimeoutSeconds 60
  }

  if (-not $DryRun) {
    $Dispatch = Run-Checked "dispatch_to_claude" {
      $Args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "scripts\send-claude-task.ps1"), "-ProjectId", $Project.id, "-TaskPath", (Resolve-Path $TaskPath).Path, "-WaitSeconds", "$WaitSeconds", "-PollSeconds", "$PollSeconds")
      if ($UseUiA) { $Args += "-UseUiA" }
      $Raw = Invoke-ProcessWithTimeout -FileName "powershell" -Arguments $Args -WorkingDirectory $Root -TimeoutSeconds ($WaitSeconds + 90)
      $Parsed = $Raw.stdout | ConvertFrom-Json
      if (-not $Parsed.sent) {
        throw "Claude dispatch was not verified as sent"
      }
      if ($Parsed.observed_kind -eq "none") {
        throw "Claude produced no matching ack/report/diff"
      }
      [ordered]@{
        exit_code = $Raw.exit_code
        dispatch = $Parsed
        stderr = $Raw.stderr
      }
    }
  } else {
    Add-Event "dispatch_to_claude" "skipped" "DryRun"
  }

  $Guard = Run-Checked "roadmap_guard" {
    $Args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "scripts\check-cailiao-roadmap-guard.ps1"), "-ProjectId", $Project.id)
    $Raw = Invoke-ProcessWithTimeout -FileName "powershell" -Arguments $Args -WorkingDirectory $Root -TimeoutSeconds 60
    if ($Raw.exit_code -ne 0) {
      throw "ROADMAP guard failed"
    }
    $Raw.stdout | ConvertFrom-Json
  }

  $GitStatusBeforeGate = Run-Checked "git_status_after_claude" {
    @(& git -c "safe.directory=$Repo" -C $Repo status --short)
  }

  if (-not $SkipFullGate) {
    $Gate = Run-Checked "quality_gates" {
      $Raw = Invoke-ProcessWithTimeout -FileName "python" -Arguments @("tools\run_quality_gates.py", "--json") -WorkingDirectory $Repo -TimeoutSeconds $GateTimeoutSeconds
      if ($Raw.exit_code -ne 0) {
        throw "quality gates failed: $($Raw.stderr)"
      }
      $Raw.stdout | ConvertFrom-Json
    }
  } else {
    Add-Event "quality_gates" "skipped" "SkipFullGate"
  }

  $DiffCheck = Run-Checked "git_diff_check" {
    $Raw = Invoke-ProcessWithTimeout -FileName "git" -Arguments @("-c", "safe.directory=$Repo", "-C", $Repo, "diff", "--check") -WorkingDirectory $Repo -TimeoutSeconds 120
    if ($Raw.exit_code -ne 0) {
      throw "git diff --check failed: $($Raw.stdout) $($Raw.stderr)"
    }
    [ordered]@{ stdout = $Raw.stdout; stderr = $Raw.stderr }
  }

  $GitStatus = @(& git -c "safe.directory=$Repo" -C $Repo status --short)
  if ($GitStatus) {
    if (-not $CommitMessage) {
      throw "Repo has changes but -CommitMessage was not supplied"
    }
    if ($DryRun) {
      Add-Event "commit" "skipped" ([ordered]@{ reason = "DryRun"; status = $GitStatus })
    } else {
      $Commit = Run-Checked "commit" {
        & git -c "safe.directory=$Repo" -C $Repo add -A
        if ($LASTEXITCODE -ne 0) { throw "git add failed" }
        & git -c "safe.directory=$Repo" -C $Repo commit -m $CommitMessage
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
        (& git -c "safe.directory=$Repo" -C $Repo log -1 --oneline) -join "`n"
      }
    }
  } else {
    Add-Event "commit" "skipped" "No Windows repo changes"
  }

  if ($Push) {
    if ($DryRun) {
      Add-Event "push" "skipped" "DryRun"
    } else {
      $PushResult = Run-Checked "push" {
        $Raw = Invoke-ProcessWithTimeout -FileName "git" -Arguments @("-c", "safe.directory=$Repo", "-C", $Repo, "push", "origin", $Project.branch) -WorkingDirectory $Repo -TimeoutSeconds 300
        if ($Raw.exit_code -ne 0) {
          throw "git push failed: $($Raw.stderr)"
        }
        [ordered]@{ stdout = $Raw.stdout; stderr = $Raw.stderr }
      }
    }
  } else {
    Add-Event "push" "skipped" "Pass -Push to publish"
  }

  if ($WatchCi -and $Push) {
    $Ci = Run-Checked "ci_watch" {
      if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "gh not found"
      }
      if ($Project.github -notmatch 'github\.com/([^/]+/[^/]+)') {
        throw "GitHub repo slug not found in project config"
      }
      $RepoSlug = $Matches[1]
      Start-Sleep -Seconds 8
      $RunListRaw = & gh run list --repo $RepoSlug --branch $Project.branch --limit 1 --json databaseId,status,conclusion,headSha
      if ($LASTEXITCODE -ne 0) { throw "gh run list failed" }
      $Run = ($RunListRaw | ConvertFrom-Json | Select-Object -First 1)
      if (-not $Run) { throw "No GitHub Actions run found" }
      & gh run watch $Run.databaseId --repo $RepoSlug --exit-status --interval 10
      if ($LASTEXITCODE -ne 0) { throw "CI failed for run $($Run.databaseId)" }
      $Run
    }
  } elseif ($WatchCi) {
    Add-Event "ci_watch" "skipped" "Requires -Push"
  }

  if ($SyncWsl) {
    $Sync = Run-Checked "sync_wsl_from_windows" {
      $Args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "scripts\sync-wsl-from-windows-bundle.ps1"), "-ProjectId", $Project.id)
      $Raw = Invoke-ProcessWithTimeout -FileName "powershell" -Arguments $Args -WorkingDirectory $Root -TimeoutSeconds 300
      if ($Raw.exit_code -ne 0) {
        throw "sync failed: $($Raw.stderr)"
      }
      $Raw.stdout | ConvertFrom-Json
    }
  }

  $Status = Run-Checked "status_dashboard" {
    $Args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "scripts\get-cailiao-status.ps1"), "-ProjectId", $Project.id)
    if ($WatchCi) { $Args += "-IncludeCi" }
    $Raw = Invoke-ProcessWithTimeout -FileName "powershell" -Arguments $Args -WorkingDirectory $Root -TimeoutSeconds 90
    $Raw.stdout | ConvertFrom-Json
  }

  Save-Log "ok"
  [ordered]@{
    ok = $true
    project = $Project.id
    run_id = $RunId
    log = $LogPath
    status = $Status
  } | ConvertTo-Json -Depth 10
} catch {
  Save-Log "failed"
  throw
}
