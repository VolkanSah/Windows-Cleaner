#Requires -RunAsAdministrator
# Windows Cleaner — mit Speicherplatz-Tracking pro Kategorie

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
        Write-Host "  ✓ $label — $mb MB freigegeben" -ForegroundColor Green
    } else {
        Write-Host "  · $label — nichts freigegeben (oder Messung zu schnell)" -ForegroundColor DarkGray
    }
    return $freed
}

$total = 0
Write-Host "`n===  Windows Cleaner  ===" -ForegroundColor Cyan
Write-Host "Laufwerk C: — Freier Speicher vorher: $(Format-MB (Get-FreeSpace)) MB`n"

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

$total += Run-Step "Thumbnail-Cache" {
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue
}

$total += Run-Step "Papierkorb" {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

$total += Run-Step "IE/Edge Legacy Cache" {
    Start-Process "RunDll32.exe" -ArgumentList "InetCpl.cpl,ClearMyTracksByProcess 255" -Wait
}

# === Windows Update Cache ===
Write-Host "`n[ Windows Update ]" -ForegroundColor Yellow

$total += Run-Step "Update Download-Cache" {
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
}

# === Disk Cleanup ===
Write-Host "`n[ Disk Cleanup ]" -ForegroundColor Yellow
# Einmalig konfigurieren: cleanmgr /sageset:1
$total += Run-Step "cleanmgr /sagerun:1" {
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
}

# === DISM & SFC (kein sinnvolles Space-Tracking — dauern zu lang) ===
Write-Host "`n[ System-Reparatur — läuft im Hintergrund, kein Space-Tracking ]" -ForegroundColor Yellow
Write-Host "  → DISM RestoreHealth..." -ForegroundColor DarkGray
DISM /Online /Cleanup-Image /RestoreHealth | Out-Null

Write-Host "  → SFC scannen..." -ForegroundColor DarkGray
sfc /scannow | Out-Null

# Auskommentiert: /ResetBase entfernt Update-Rollback-Möglichkeit
# DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase

# === Event Logs ===
Write-Host "`n[ Event Logs ]" -ForegroundColor Yellow
$total += Run-Step "Alle Event Logs" {
    Get-WinEvent -ListLog * | Where-Object { $_.IsEnabled } | ForEach-Object {
        try { [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($_.LogName) } catch {}
    }
}

# === Netzwerk ===
Write-Host "`n[ Netzwerk ]" -ForegroundColor Yellow

Run-Step "DNS Cache flush" { ipconfig /flushdns | Out-Null } | Out-Null
Write-Host "  → TCP/IP & Winsock reset (Neustart empfohlen danach)" -ForegroundColor DarkGray
netsh int ip reset | Out-Null
netsh winsock reset | Out-Null

# === Ergebnis ===
Write-Host "`n=========================" -ForegroundColor Cyan
Write-Host "Gesamt freigegeben: $(Format-MB $total) MB" -ForegroundColor Green
Write-Host "Freier Speicher jetzt: $(Format-MB (Get-FreeSpace)) MB"
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "`nHinweis: Netzwerk-Reset wird erst nach Neustart aktiv.`n" -ForegroundColor DarkYellow
