#Requires -RunAsAdministrator
# Windows Cleaner — with per-category space tracking

function Get-FreeSpace {
    return (Get-Volume -DriveLetter C).SizeRemaining
}

function Format-MB { param($bytes)
    return [math]::Round($bytes / 1MB, 1)
}

function Run-Step {
    param($label, $scriptblock)
    $before = Get-FreeSpace
    & $scriptblock
    $freed = (Get-FreeSpace) - $before
    $mb = Format-MB $freed
    if ($freed -gt 0) {
        Write-Host "  ✓ $label — $mb MB freed" -ForegroundColor Green
    } else {
        Write-Host "  · $label — nothing freed (or measurement too fast)" -ForegroundColor DarkGray
    }
    return $freed
}

$total = 0
Write-Host "`n===  Windows Cleaner  ===" -ForegroundColor Cyan
Write-Host "Drive C: — Free space before: $(Format-MB (Get-FreeSpace)) MB`n"

# === Temp & Cache ===
Write-Host "[ Temp & Cache ]" -ForegroundColor Yellow

$total += Run-Step "User Temp (%TEMP%)" {
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Run-Step "Windows Temp" {
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Run-Step "Prefetch" {
    Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Run-Step "Thumbnail Cache" {
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue
}

$total += Run-Step "Recycle Bin" {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

$total += Run-Step "IE/Edge Legacy Cache" {
    Start-Process "RunDll32.exe" -ArgumentList "InetCpl.cpl,ClearMyTracksByProcess 255" -Wait
}

# === Windows Update Cache ===
Write-Host "`n[ Windows Update ]" -ForegroundColor Yellow

$total += Run-Step "Update Download Cache" {
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
}

# === Disk Cleanup ===
Write-Host "`n[ Disk Cleanup ]" -ForegroundColor Yellow
# One-time setup required: run cleanmgr /sageset:1 to configure categories
$total += Run-Step "cleanmgr /sagerun:1" {
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
}

# === DISM & SFC (no space tracking — runtime too long for meaningful delta) ===
Write-Host "`n[ System Repair — runs in background, no space tracking ]" -ForegroundColor Yellow

# WARNING: DISM can take 10-30 minutes and shows no progress (output suppressed).
# As long as DISM.exe + Dismhost.exe appear in Task Manager, it is working.
# Comment out if you don't need system repair:
Write-Host "  → DISM RestoreHealth..." -ForegroundColor DarkGray
DISM /Online /Cleanup-Image /RestoreHealth | Out-Null

Write-Host "  → SFC scan..." -ForegroundColor DarkGray
sfc /scannow | Out-Null

# Commented out: /ResetBase permanently removes Update rollback points — opt-in only
# DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase

# === Event Logs ===
Write-Host "`n[ Event Logs ]" -ForegroundColor Yellow

$total += Run-Step "All Event Logs" {
    Get-WinEvent -ListLog * | Where-Object { $_.IsEnabled } | ForEach-Object {
        try { [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName) } catch {}
    }
}

# === Network ===
Write-Host "`n[ Network ]" -ForegroundColor Yellow

Run-Step "DNS Cache Flush" { ipconfig /flushdns | Out-Null } | Out-Null
Write-Host "  → TCP/IP & Winsock reset (reboot recommended afterward)" -ForegroundColor DarkGray
netsh int ip reset | Out-Null
netsh winsock reset | Out-Null

# === Summary ===
Write-Host "`n=========================" -ForegroundColor Cyan
Write-Host "Total freed: $(Format-MB $total) MB" -ForegroundColor Green
Write-Host "Free space now: $(Format-MB (Get-FreeSpace)) MB"
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "`nNote: Network reset takes effect after reboot.`n" -ForegroundColor DarkYellow
