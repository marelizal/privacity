# PowerShell wrapper for Privacity (Windows compatibility)
# ------------------------------------------------------------
# Requirements: OpenVPN installed at C:\Program Files\OpenVPN\bin\openvpn.exe
#
# Usage:
#   privacity -ListCountries
#   privacity -Country "United States" -Fast
#   privacity -Country "Japan"
#   privacity -Status
#   privacity -Disconnect
#
param(
    [switch]$ListCountries,
    [switch]$Status,
    [switch]$Disconnect,
    [string]$Country,
    [switch]$Fast,
    [int]$Count = 1,
    [int]$Retries = 3         # how many servers to try before giving up
)

$PidFile = Join-Path $env:TEMP "privacity.pid"

function Get-ServersCsv {
    $csvUrl = "https://www.vpngate.net/api/iphone/"
    $tempFile = Join-Path $env:TEMP "vpngate.csv"
    Write-Host "Downloading server list..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $csvUrl -OutFile $tempFile -UseBasicParsing
    return $tempFile
}

function Parse-Servers ($csvPath) {
    $raw = Get-Content $csvPath -Raw
    $allLines = $raw -split "\r?\n"
    $headerIdx = -1
    for ($i = 0; $i -lt $allLines.Length; $i++) {
        if ($allLines[$i] -like "#HostName*") { $headerIdx = $i; break }
    }
    if ($headerIdx -lt 0) { throw "Unable to locate CSV header" }
    $header = $allLines[$headerIdx].TrimStart('#')
    $dataLines = $allLines[($headerIdx+1)..($allLines.Length-1)] | Where-Object { $_ -and $_ -notmatch '^\*' }
    @($header) + $dataLines | ConvertFrom-Csv -Delimiter ','
}

function List-Countries ($servers) {
    $servers | Where-Object { $_.CountryLong -ne "" } |
        Select-Object -ExpandProperty CountryLong -Unique | Sort-Object |
        ForEach-Object { Write-Host "* $_" }
}

function Get-Candidates ($servers) {
    # Returns top N candidates sorted by preference
    if ($Country) {
        $filtered = $servers | Where-Object { $_.CountryLong -like "*$Country*" }
        if (-not $filtered) {
            Write-Host "No servers available for '$Country' right now (VPNGate list changes frequently). Try again or use -ListCountries to see current options." -ForegroundColor Yellow
            exit 1
        }
    } else {
        $filtered = $servers
    }
    if ($Fast) {
        $withPing = $filtered | Where-Object { $_.Ping -match '^\d+$' }
        if ($withPing) { $filtered = $withPing }
        # Sort safely: non-numeric ping treated as MaxValue (worst)
        return $filtered | Sort-Object { if ($_.Ping -match '^\d+$') { [int]$_.Ping } else { [int]::MaxValue } } | Select-Object -First ($Retries * 2)
    } else {
        return $filtered | Sort-Object -Property Score -Descending | Select-Object -First ($Retries * 2)
    }
}

function Start-OpenVPN ($server, $openvpnPath) {
    $ovpnBase64 = $server.OpenVPN_ConfigData_Base64
    if (-not $ovpnBase64) { return $null }
    $config = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($ovpnBase64.Trim()))

    # Replace 'dev tun' with 'dev tap' for Windows TAP-Windows6 driver compatibility
    $config = $config -replace '(?im)^\s*dev\s+tun\b', 'dev tap'

    $configPath = Join-Path $env:TEMP "privacity_$(Get-Random).ovpn"
    Set-Content -Path $configPath -Value $config -Encoding ASCII

    $proc = Start-Process -FilePath $openvpnPath `
        -ArgumentList "--config `"$configPath`" --allow-deprecated-insecure-static-crypto" `
        -PassThru -NoNewWindow
    return $proc
}

function Connect-WithRetry ($candidates, $openvpnPath) {
    # Kill any existing session first
    if (Test-Path $PidFile) {
        $oldPid = (Get-Content $PidFile -Raw).Trim()
        if (Get-Process -Id $oldPid -ErrorAction SilentlyContinue) {
            Write-Host "Disconnecting existing session (PID $oldPid)..." -ForegroundColor Yellow
            Stop-Process -Id $oldPid -Force
            Start-Sleep -Seconds 2
        }
        Remove-Item $PidFile -ErrorAction SilentlyContinue
    }

    foreach ($server in $candidates) {
        Write-Host "`nTrying: $($server.HostName)  [$($server.CountryLong)]  Ping=$($server.Ping)" -ForegroundColor Cyan
        $proc = Start-OpenVPN $server $openvpnPath
        if (-not $proc) { Write-Host "  Skipped (no config data)." -ForegroundColor DarkGray; continue }

        # Wait up to 8 seconds to see if the process survives (quick failures exit immediately)
        $deadline = (Get-Date).AddSeconds(8)
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 500
            if ($proc.HasExited) { break }
        }

        if (-not $proc.HasExited) {
            Write-Host "OpenVPN connected! PID: $($proc.Id)" -ForegroundColor Green
            Set-Content -Path $PidFile -Value $proc.Id -Encoding ASCII
            return
        } else {
            Write-Host "  Server failed (exit code $($proc.ExitCode)), trying next..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1  # give TAP adapter time to release
        }
    }

    Write-Host "`nAll servers failed. Try a different country or run again." -ForegroundColor Red
}

# ------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------

if ($Status) {
    if (Test-Path $PidFile) {
        $savedPid = (Get-Content $PidFile -Raw).Trim()
        if (Get-Process -Id $savedPid -ErrorAction SilentlyContinue) {
            Write-Host "OpenVPN is running (PID $savedPid)." -ForegroundColor Green
        } else {
            Write-Host "OpenVPN PID file found but process is not running." -ForegroundColor Yellow
            Remove-Item $PidFile -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "OpenVPN is not running." -ForegroundColor Yellow
    }
    exit 0
}

if ($Disconnect) {
    if (Test-Path $PidFile) {
        $savedPid = (Get-Content $PidFile -Raw).Trim()
        Stop-Process -Id $savedPid -Force -ErrorAction SilentlyContinue
        Remove-Item $PidFile -ErrorAction SilentlyContinue
    } else {
        Get-Process openvpn -ErrorAction SilentlyContinue | Stop-Process -Force
    }
    Write-Host "OpenVPN terminated." -ForegroundColor Red
    exit 0
}

$csvPath = Get-ServersCsv
$servers = Parse-Servers $csvPath

if ($ListCountries) { List-Countries $servers; exit 0 }

$openvpnPath = "C:\Program Files\OpenVPN\bin\openvpn.exe"
if (-not (Test-Path $openvpnPath)) {
    $openvpnPath = (Get-Command openvpn -ErrorAction SilentlyContinue).Source
    if (-not $openvpnPath) { Write-Error "OpenVPN not found. Install from https://openvpn.net"; exit 1 }
}

$candidates = Get-Candidates $servers
Write-Host "Candidates:" -ForegroundColor Cyan
$candidates | Format-Table HostName, CountryLong, Score, Ping

Connect-WithRetry $candidates $openvpnPath
