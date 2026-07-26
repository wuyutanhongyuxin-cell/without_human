param(
  [Parameter(Mandatory=$true)][string]$PromptPath,
  [string]$OutputPath = "",
  [string]$Model = $env:DEEPSEEK_MODEL,
  [string]$BaseUrl = $env:DEEPSEEK_BASE_URL,
  [int]$MaxTokens = 1600,
  [ValidateSet("Auto", "InvokeRestMethod", "Curl")][string]$Transport = "Auto"
)

$ErrorActionPreference = "Stop"

function Get-EnvOrUser([string]$Name) {
  $Value = [Environment]::GetEnvironmentVariable($Name, "Process")
  if (-not $Value) {
    $Value = [Environment]::GetEnvironmentVariable($Name, "User")
  }
  return $Value
}

function New-DeepSeekBodyJson([string]$ResolvedModel, [string]$SystemPrompt,
                              [string]$UserPrompt, [int]$TokenLimit) {
  $BodyObject = [ordered]@{
    model = $ResolvedModel
    messages = @(
      [ordered]@{ role = "system"; content = $SystemPrompt },
      [ordered]@{ role = "user"; content = $UserPrompt }
    )
    max_tokens = $TokenLimit
    stream = $false
  }
  $Json = $BodyObject | ConvertTo-Json -Depth 8 -Compress
  $Bytes = [Text.UTF8Encoding]::new($false).GetBytes($Json)
  if ($Bytes.Length -gt 1048576) {
    throw "DeepSeek request body is unexpectedly large ($($Bytes.Length) bytes). Refusing to send."
  }
  return [pscustomobject]@{ Json = $Json; Bytes = $Bytes }
}

function Get-DeepSeekText($Response) {
  if (-not $Response) {
    throw "DeepSeek returned an empty response."
  }
  $Text = $Response.choices[0].message.content
  if ($null -eq $Text) {
    throw "DeepSeek response did not contain choices[0].message.content."
  }
  if ([string]::IsNullOrWhiteSpace([string]$Text)) {
    throw "DeepSeek returned empty message content. Increase -MaxTokens or inspect the prompt/model."
  }
  return [string]$Text
}

function Invoke-DeepSeekWithRestMethod([string]$Uri, [string]$ApiKey, [byte[]]$BodyBytes) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $Headers = @{
    "Authorization" = "Bearer $ApiKey"
    "Content-Type" = "application/json; charset=utf-8"
  }
  Invoke-RestMethod -Method Post -Uri $Uri -Headers $Headers -Body $BodyBytes -TimeoutSec 120
}

function Invoke-DeepSeekWithCurl([string]$Uri, [string]$ApiKey, [string]$BodyJson) {
  $Curl = (Get-Command curl.exe -ErrorAction SilentlyContinue).Source
  if (-not $Curl) {
    throw "curl.exe not found; cannot use Curl transport."
  }

  $TempDir = [IO.Path]::GetTempPath()
  $BodyPath = Join-Path $TempDir ("deepseek-body-" + [guid]::NewGuid().ToString("N") + ".json")
  $OutPath = Join-Path $TempDir ("deepseek-response-" + [guid]::NewGuid().ToString("N") + ".json")
  $ErrPath = Join-Path $TempDir ("deepseek-curl-" + [guid]::NewGuid().ToString("N") + ".err")
  try {
    [IO.File]::WriteAllText($BodyPath, $BodyJson, [Text.UTF8Encoding]::new($false))
    & $Curl -sS -X POST $Uri `
      -H ("Authorization: Bearer " + $ApiKey) `
      -H "Content-Type: application/json; charset=utf-8" `
      --data-binary ("@" + $BodyPath) `
      -o $OutPath 2> $ErrPath
    if ($LASTEXITCODE -ne 0) {
      $ErrText = ""
      if (Test-Path $ErrPath) {
        $ErrText = (Get-Content -LiteralPath $ErrPath -Raw -ErrorAction SilentlyContinue)
      }
      throw "curl.exe DeepSeek request failed with exit code $LASTEXITCODE. $ErrText"
    }
    $Raw = Get-Content -LiteralPath $OutPath -Raw -Encoding UTF8
    $Parsed = $Raw | ConvertFrom-Json
    if ($Parsed.error) {
      $Message = [string]$Parsed.error.message
      $Type = [string]$Parsed.error.type
      $Code = [string]$Parsed.error.code
      throw "DeepSeek API error: $Message type=$Type code=$Code"
    }
    return $Parsed
  } finally {
    Remove-Item -LiteralPath $BodyPath, $OutPath, $ErrPath -Force -ErrorAction SilentlyContinue
  }
}

if (-not $Model) { $Model = Get-EnvOrUser "DEEPSEEK_MODEL" }
if (-not $BaseUrl) { $BaseUrl = Get-EnvOrUser "DEEPSEEK_BASE_URL" }
$ApiKey = Get-EnvOrUser "DEEPSEEK_API_KEY"

if (-not $Model) { $Model = "deepseek-v4-flash" }
if (-not $BaseUrl) { $BaseUrl = "https://api.deepseek.com" }
if (-not $ApiKey) {
  throw "DEEPSEEK_API_KEY is not set. Store it outside the repo, e.g. as a user environment variable or in your launcher environment."
}
if (-not (Test-Path -LiteralPath $PromptPath)) {
  throw "Prompt file not found: $PromptPath"
}

$Prompt = Get-Content -LiteralPath $PromptPath -Raw -Encoding UTF8
$System = @"
You are a low-risk delegated assistant in the without_human workflow.
Return concise, auditable text only.
Do not claim you executed commands, changed files, read secrets, or verified runtime state.
If the task requires repository writes, credentials, pushing, tests, or high-risk judgment, say: ESCALATE_TO_CODEX.
"@

$Uri = ($BaseUrl.TrimEnd("/") + "/chat/completions")
$Body = New-DeepSeekBodyJson -ResolvedModel $Model -SystemPrompt $System `
  -UserPrompt $Prompt -TokenLimit $MaxTokens

$Response = $null
if ($Transport -eq "InvokeRestMethod") {
  $Response = Invoke-DeepSeekWithRestMethod -Uri $Uri -ApiKey $ApiKey -BodyBytes $Body.Bytes
} elseif ($Transport -eq "Curl") {
  $Response = Invoke-DeepSeekWithCurl -Uri $Uri -ApiKey $ApiKey -BodyJson $Body.Json
} else {
  try {
    $Response = Invoke-DeepSeekWithRestMethod -Uri $Uri -ApiKey $ApiKey -BodyBytes $Body.Bytes
  } catch {
    Write-Warning ("Invoke-RestMethod transport failed; retrying with curl.exe. " + $_.Exception.Message)
    $Response = Invoke-DeepSeekWithCurl -Uri $Uri -ApiKey $ApiKey -BodyJson $Body.Json
  }
}

$Text = Get-DeepSeekText $Response
if ($OutputPath) {
  Set-Content -LiteralPath $OutputPath -Value $Text -Encoding UTF8
}

$Text
