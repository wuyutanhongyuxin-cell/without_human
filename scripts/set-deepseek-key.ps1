param(
  [string]$Model = "deepseek-v4-flash",
  [string]$BaseUrl = "https://api.deepseek.com"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "DeepSeek API key setup" -ForegroundColor Cyan
Write-Host "The key will be stored as a Windows User environment variable."
Write-Host "It will not be written to this repository."
Write-Host ""

$Secure = Read-Host "Paste DeepSeek API key" -AsSecureString
$Bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
try {
  $Key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Bstr)
} finally {
  if ($Bstr -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Bstr)
  }
}

if ([string]::IsNullOrWhiteSpace($Key)) {
  throw "No key entered."
}

[Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", $Key, "User")
[Environment]::SetEnvironmentVariable("DEEPSEEK_MODEL", $Model, "User")
[Environment]::SetEnvironmentVariable("DEEPSEEK_BASE_URL", $BaseUrl, "User")

Write-Host ""
Write-Host "Saved DEEPSEEK_API_KEY, DEEPSEEK_MODEL, and DEEPSEEK_BASE_URL to User environment." -ForegroundColor Green
Write-Host "Close this window when ready."
Read-Host "Press Enter to close"
