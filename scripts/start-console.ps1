$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$HostName = "127.0.0.1"
$StartPort = 8787
$MaxPort = 8899
$KnownPortMax = 8795

function Test-HttpConsole {
    param([int]$Port)
    try {
        $url = "http://${HostName}:$Port/"
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
            $content = & $curl.Source --noproxy "*" -s --max-time 2 $url
            return ($LASTEXITCODE -eq 0 -and $content -like "*Without Human*")
        }
        $res = Invoke-WebRequest -Uri $url -UseBasicParsing -Proxy $null -TimeoutSec 2
        return ($res.Content -like "*Without Human*")
    } catch {
        return $false
    }
}

function Test-PortFree {
    param([int]$Port)
    $listener = $null
    try {
        $address = [System.Net.IPAddress]::Parse($HostName)
        $listener = [System.Net.Sockets.TcpListener]::new($address, $Port)
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        if ($listener) {
            $listener.Stop()
        }
    }
}

function Wait-Console {
    param([int]$Port)
    for ($i = 0; $i -lt 40; $i++) {
        if (Test-HttpConsole -Port $Port) {
            return $true
        }
        Start-Sleep -Milliseconds 250
    }
    return $false
}

for ($port = $StartPort; $port -le $KnownPortMax; $port++) {
    if (-not (Test-PortFree -Port $port)) {
        if (Test-HttpConsole -Port $port) {
            Start-Process "http://${HostName}:$port/"
            exit 0
        }
    }
}

$selectedPort = $null
for ($port = $StartPort; $port -le $MaxPort; $port++) {
    if (Test-PortFree -Port $port) {
        $selectedPort = $port
        break
    }
}

if (-not $selectedPort) {
    throw "No free localhost port found in $StartPort-$MaxPort."
}

$python = (Get-Command python -ErrorAction Stop).Source
$env:WITHOUT_HUMAN_PORT = [string]$selectedPort

Start-Process -FilePath $python `
    -ArgumentList @("control/server.py") `
    -WorkingDirectory $Root `
    -WindowStyle Hidden | Out-Null

if (-not (Wait-Console -Port $selectedPort)) {
    throw "Without Human console did not become ready on port $selectedPort."
}

Start-Process "http://${HostName}:$selectedPort/"
