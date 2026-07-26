param(
  [string]$ProjectId = "cailiao",
  [switch]$NoStash
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ProjectsPath = Join-Path $Root "control\projects.json"
$Config = Get-Content $ProjectsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Project = $Config.projects | Where-Object { $_.id -eq $ProjectId } | Select-Object -First 1
if (-not $Project) {
  throw "Project not found: $ProjectId"
}

$WindowsRepo = $Project.windows_repo
$Distro = $Project.wsl_distro
$WslRepo = $Project.wsl_repo
$Branch = $Project.branch
if (-not $Branch) {
  $Branch = "main"
}
if (-not (Test-Path $WindowsRepo)) {
  throw "Windows repo not found: $WindowsRepo"
}

$Head = (& git -C $WindowsRepo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $Head) {
  throw "Failed to read Windows repo HEAD"
}
$ShortHead = (& git -C $WindowsRepo rev-parse --short HEAD).Trim()
$BundlePath = Join-Path ([IO.Path]::GetTempPath()) "$ProjectId-$ShortHead.bundle"
& git -C $WindowsRepo bundle create $BundlePath HEAD
if ($LASTEXITCODE -ne 0) {
  throw "git bundle create failed"
}

function Invoke-WslBash {
  param([Parameter(Mandatory=$true)][string]$Command)
  & wsl.exe -d $Distro -- bash -lc $Command
  if ($LASTEXITCODE -ne 0) {
    throw "WSL command failed: $Command"
  }
}

function Send-BinaryToWsl {
  param(
    [Parameter(Mandatory=$true)][string]$SourcePath,
    [Parameter(Mandatory=$true)][string]$DestPath
  )
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "wsl.exe"
  $psi.Arguments = "-d $Distro -- bash -lc `"cat > '$DestPath'`""
  $psi.UseShellExecute = $false
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $proc = [System.Diagnostics.Process]::Start($psi)
  $bytes = [System.IO.File]::ReadAllBytes($SourcePath)
  $proc.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
  $proc.StandardInput.BaseStream.Close()
  $stdout = $proc.StandardOutput.ReadToEnd()
  $stderr = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()
  if ($proc.ExitCode -ne 0) {
    throw "Binary transfer failed with exit $($proc.ExitCode): $stdout $stderr"
  }
}

$RemoteBundle = "/tmp/$ProjectId-$ShortHead.bundle"
Send-BinaryToWsl -SourcePath $BundlePath -DestPath $RemoteBundle

Invoke-WslBash "cd '$WslRepo' && git bundle verify '$RemoteBundle'"

$Status = (& wsl.exe -d $Distro -- bash -lc "cd '$WslRepo' && git status --short")
if ($LASTEXITCODE -ne 0) {
  throw "Failed to read WSL repo status"
}
$Stashed = $false
if ($Status -and -not $NoStash) {
  $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  Invoke-WslBash "cd '$WslRepo' && git stash push -u -m 'codex-pre-sync-$ShortHead-$Stamp'"
  $Stashed = $true
} elseif ($Status -and $NoStash) {
  throw "WSL repo is dirty and -NoStash was set"
}

Invoke-WslBash "cd '$WslRepo' && git fetch '$RemoteBundle' HEAD:refs/remotes/localbundle/$Branch"
Invoke-WslBash "cd '$WslRepo' && git reset --hard refs/remotes/localbundle/$Branch"

$FinalStatus = (& wsl.exe -d $Distro -- bash -lc "cd '$WslRepo' && git status --short")
$FinalHead = (& wsl.exe -d $Distro -- bash -lc "cd '$WslRepo' && git rev-parse HEAD").Trim()
$FinalLog = (& wsl.exe -d $Distro -- bash -lc "cd '$WslRepo' && git log -1 --oneline").Trim()

[ordered]@{
  project = $Project.id
  windows_repo = $WindowsRepo
  wsl_repo = $WslRepo
  synced_head = $FinalHead
  expected_head = $Head
  log = $FinalLog
  clean = -not [bool]$FinalStatus
  stashed_before_sync = $Stashed
  bundle = $RemoteBundle
} | ConvertTo-Json -Depth 4
