param(
  [string]$ProjectId = "cailiao"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
function Write-DebugMarker {
  param([string]$Message)
  if ($env:WITHOUT_HUMAN_DEBUG -eq "1") {
    Write-Host "DEBUG $Message"
  }
}
Write-DebugMarker "start"
$ProjectsPath = Join-Path $Root "control\projects.json"
$Config = Get-Content $ProjectsPath -Raw -Encoding UTF8 | ConvertFrom-Json
Write-DebugMarker "config-loaded"
$Project = $Config.projects | Where-Object { $_.id -eq $ProjectId } | Select-Object -First 1
if (-not $Project) {
  throw "Project not found: $ProjectId"
}

$Repo = $Project.windows_repo
Write-DebugMarker "repo=$Repo"
if (-not (Test-Path $Repo)) {
  throw "Windows repo not found: $Repo"
}

$RoadmapPath = Join-Path $Repo "docs\ROADMAP.md"
$HandoffPath = Join-Path $Repo "CODEX_HANDOFF.json"
if (-not (Test-Path $RoadmapPath)) {
  throw "ROADMAP not found: $RoadmapPath"
}
if (-not (Test-Path $HandoffPath)) {
  throw "CODEX_HANDOFF not found: $HandoffPath"
}

$RoadmapLines = Get-Content $RoadmapPath -Encoding UTF8
Write-DebugMarker "roadmap-loaded"
$Utf8 = [System.Text.Encoding]::UTF8
function Decode-Utf8Base64 {
  param([string]$Value)
  $Utf8.GetString([Convert]::FromBase64String($Value))
}
$Blockers = @(
  [pscustomobject]@{ id = "stage2b-real-query-set"; snippet = (Decode-Utf8Base64 "5Lq65bel5bu656uLIDUwLTEwMCDmnaHnnJ/lrp7ljL/lkI3mn6Xor6Lpm4Y=") },
  [pscustomobject]@{ id = "stage2b-real-bm25-calibration"; snippet = (Decode-Utf8Base64 "5Zyo55yf5a6e5p+l6K+i6ZuG5LiK55SoIENMSSDmiavlj4LmoKHlh4YgQk0yNQ==") },
  [pscustomobject]@{ id = "stage2b-real-vector-provider-index"; snippet = (Decode-Utf8Base64 "55yf5a6eIGVtYmVkZGluZyBwcm92aWRlcuOAgeaMgeS5heWMluWQkemHj+W6k+S4jueUn+S6p+e6p+WQkemHj+e0ouW8lQ==") },
  [pscustomobject]@{ id = "stage2b-real-reranker-rrf"; snippet = (Decode-Utf8Base64 "55yf5a6e6YeN5o6S5qih5Z6LIC8gY3Jvc3MtZW5jb2RlciBwcm92aWRlciDkuI4gUlJGIOiejeWQiOaOkuW6j+a3seWMlg==") },
  [pscustomobject]@{ id = "stage2b-real-nli-llm-conflict-evidence"; snippet = (Decode-Utf8Base64 "5byV55So6JW05ZCr5LiO5a6M5pW06K+t5LmJ57qn5Yay56qB6K+B5o2u5qOA5rWL") }
)

$Findings = New-Object System.Collections.ArrayList
foreach ($BlockerSpec in $Blockers) {
  Write-DebugMarker "scan-blocker"
  $Match = $null
  for ($Index = 0; $Index -lt $RoadmapLines.Count; $Index++) {
    if ($RoadmapLines[$Index].Contains($BlockerSpec.snippet)) {
      $Match = [pscustomobject]@{
        blocker_id = $BlockerSpec.id
        line_number = $Index + 1
        unchecked = $RoadmapLines[$Index].TrimStart().StartsWith("- [ ]")
      }
      break
    }
  }
  if (-not $Match) {
    $Match = [pscustomobject]@{
      blocker_id = $BlockerSpec.id
      line_number = $null
      unchecked = $false
      missing = $true
    }
  }
  [void]$Findings.Add($Match)
}
Write-DebugMarker "findings-built"

$HandoffRaw = Get-Content $HandoffPath -Raw -Encoding UTF8
Write-DebugMarker "handoff-raw-loaded"
$Handoff = $HandoffRaw | ConvertFrom-Json
Write-DebugMarker "handoff-json-loaded"
$HandoffRisks = @()
if ($HandoffRaw -match '"roadmap_parent_items_checked"\s*:\s*true') {
  $HandoffRisks += "CODEX_HANDOFF sets roadmap_parent_items_checked=true"
}
if ($HandoffRaw -match '"ready_for_stage2b_completion"\s*:\s*true') {
  $HandoffRisks += "CODEX_HANDOFF sets ready_for_stage2b_completion=true"
}
Write-DebugMarker "handoff-risks-built"

$Ok = (($Findings | Where-Object { -not $_.unchecked }).Count -eq 0) -and ($HandoffRisks.Count -eq 0)
Write-DebugMarker "ok-computed"
$Result = [pscustomobject]@{
  project = $Project.id
  repo = $Repo
  ok = $Ok
  roadmap = $RoadmapPath
  handoff = $HandoffPath
  handoff_task_id = $Handoff.task_id
  guarded_blockers = $Findings
  handoff_risks = $HandoffRisks
}
Write-DebugMarker "result-built"
$Result | ConvertTo-Json -Depth 8
Write-DebugMarker "json-written"

if (-not $Ok) {
  exit 1
}
