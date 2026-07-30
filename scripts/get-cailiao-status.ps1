param(
  [string]$ProjectId = "cailiao",
  [int]$GhLimit = 5,
  [switch]$IncludeCi
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ProjectsPath = Join-Path $Root "control\projects.json"
$Config = Get-Content $ProjectsPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Project = $Config.projects | Where-Object { $_.id -eq $ProjectId } | Select-Object -First 1
if (-not $Project) {
  throw "Project not found: $ProjectId"
}

$Repo = $Project.windows_repo
if (-not (Test-Path $Repo)) {
  throw "Windows repo not found: $Repo"
}

function Invoke-GitText {
  param([string[]]$GitArgs)
  $Output = & git -c "safe.directory=$Repo" -C $Repo @GitArgs
  if ($LASTEXITCODE -ne 0) {
    throw "git $($GitArgs -join ' ') failed"
  }
  $Output
}

$Head = (Invoke-GitText -GitArgs @("log", "-1", "--oneline")) -join "`n"
$Branch = (Invoke-GitText -GitArgs @("branch", "--show-current")) -join "`n"
$Status = @(Invoke-GitText -GitArgs @("status", "--short"))

$RoadmapPath = Join-Path $Repo "docs\ROADMAP.md"
$HandoffPath = Join-Path $Repo "CODEX_HANDOFF.json"
$OpenBlockers = @()
if (Test-Path $RoadmapPath) {
  $Lines = Get-Content $RoadmapPath -Encoding UTF8
  for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
    if ($Lines[$Index] -match '^\s*-\s+\[ \]') {
      $OpenBlockers += [ordered]@{
        line_number = $Index + 1
        checked = $false
      }
    }
  }
}

$Handoff = $null
if (Test-Path $HandoffPath) {
  $Handoff = Get-Content $HandoffPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

$GhRuns = @()
$Gh = Get-Command gh -ErrorAction SilentlyContinue
if ($IncludeCi -and $Gh -and $Project.github -match 'github\.com/([^/]+/[^/]+)') {
  $RepoSlug = $Matches[1]
  try {
    $GhRuns = @(& gh run list --repo $RepoSlug --branch $Project.branch --limit $GhLimit --json databaseId,status,conclusion,displayTitle,headSha,createdAt 2>$null | ConvertFrom-Json)
  } catch {
    $GhRuns = @([ordered]@{ error = $_.Exception.Message })
  }
}

[ordered]@{
  project = $Project.id
  repo = $Repo
  branch = $Branch.Trim()
  head = $Head.Trim()
  clean = -not [bool]$Status
  status = $Status
  open_roadmap_items = $OpenBlockers
  handoff_task_id = if ($Handoff) { $Handoff.task_id } else { $null }
  handoff_phase = if ($Handoff) { $Handoff.phase } else { $null }
  ci_included = [bool]$IncludeCi
  ci_runs = $GhRuns
  next_step = if ($OpenBlockers.Count -gt 0) { "Stage 2B real external evidence remains blocked; keep parent items unchecked." } else { "No unchecked ROADMAP items detected; run final gates and human release review." }
} | ConvertTo-Json -Depth 8
