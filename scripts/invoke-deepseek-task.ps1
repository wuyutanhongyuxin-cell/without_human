param(
  [Parameter(Mandatory=$true)][string]$PromptPath,
  [string]$OutputPath = "",
  [string]$Model = $env:DEEPSEEK_MODEL,
  [string]$BaseUrl = $env:DEEPSEEK_BASE_URL,
  [int]$MaxTokens = 1600
)

$ErrorActionPreference = "Stop"
if (-not $Model) { $Model = "deepseek-v4-flash" }
if (-not $BaseUrl) { $BaseUrl = "https://api.deepseek.com" }
if (-not $env:DEEPSEEK_API_KEY) {
  throw "DEEPSEEK_API_KEY is not set. Store it outside the repo, e.g. as a user environment variable or in your launcher environment."
}
if (-not (Test-Path $PromptPath)) {
  throw "Prompt file not found: $PromptPath"
}

$Prompt = Get-Content -LiteralPath $PromptPath -Raw -Encoding UTF8
$System = @"
You are a low-risk delegated assistant in the without_human workflow.
Return concise, auditable text only.
Do not claim you executed commands, changed files, read secrets, or verified runtime state.
If the task requires repository writes, credentials, pushing, tests, or high-risk judgment, say: ESCALATE_TO_CODEX.
"@

$Body = @{
  model = $Model
  messages = @(
    @{ role = "system"; content = $System },
    @{ role = "user"; content = $Prompt }
  )
  thinking = @{ type = "disabled" }
  max_tokens = $MaxTokens
  stream = $false
} | ConvertTo-Json -Depth 8

$Headers = @{
  "Authorization" = "Bearer $($env:DEEPSEEK_API_KEY)"
  "Content-Type" = "application/json"
}

$Uri = ($BaseUrl.TrimEnd("/") + "/chat/completions")
$Response = Invoke-RestMethod -Method Post -Uri $Uri -Headers $Headers -Body $Body -TimeoutSec 120
$Text = $Response.choices[0].message.content

if ($OutputPath) {
  Set-Content -LiteralPath $OutputPath -Value $Text -Encoding UTF8
}

$Text
