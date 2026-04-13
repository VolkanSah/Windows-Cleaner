#Requires -RunAsAdministrator
#Requires -Version 5.1
# Windows Cleaner — with per-category space tracking
# Usage: .\windows_cleaner.ps1          — full clean
#        .\windows_cleaner.ps1 -WhatIf  — dry run (nothing is deleted)

[CmdletBinding(SupportsShouldProcess)]
param()

Set-StrictMode -Version Latest

# Derive the system drive letter once so every path works on non-C: installs.
# $env:SystemDrive  = e.g. "D:"   $env:SystemRoot = e.g. "D:\Windows"
$sysDriveLetter = $env:SystemDrive.TrimEnd(':')   # e.g. "D"

function Get-FreeSpace {
    [CmdletBinding()]
    [OutputType([long])]
    param()
    return (Get-Volume -DriveLetter $script:sysDriveLetter).SizeRemaining
}

function Format-MB {
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [long] $Bytes
    )
    return [math]::Round($Bytes / 1MB, 1)
}

function Invoke-CleanStep {
    [CmdletBinding()]
    [OutputType([long])]
    param(
        [Parameter(Mandatory)]
        [string] $Label,

        [Parameter(Mandatory)]
        [scriptblock] $ScriptBlock
    )
    if ($WhatIfPreference) {
        Write-Host "  ? $Label — would clean (dry run)" -ForegroundColor DarkCyan
        return [long]0
    }
    $before = Get-FreeSpace
    & $ScriptBlock
    $freed = (Get-FreeSpace) - $before
    if ($freed -gt 0) {
        Write-Host "  ✓ $Label — $(Format-MB -Bytes $freed) MB freed" -ForegroundColor Green
    } else {
        Write-Host "  · $Label — nothing freed (or measurement too fast)" -ForegroundColor DarkGray
    }
    return $freed
}

[long]$total = 0

if ($WhatIfPreference) {
    Write-Host "`n===  Windows Cleaner (DRY RUN — nothing will be deleted)  ===" -ForegroundColor Cyan
} else {
    Write-Host "`n===  Windows Cleaner  ===" -ForegroundColor Cyan
}
Write-Host "Drive $env:SystemDrive — Free space before: $(Format-MB -Bytes (Get-FreeSpace)) MB`n"

# === Temp & Cache ===
Write-Host '[ Temp & Cache ]' -ForegroundColor Yellow

$total += Invoke-CleanStep -Label 'User Temp (%TEMP%)' -ScriptBlock {
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Windows Temp' -ScriptBlock {
    Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Prefetch' -ScriptBlock {
    Remove-Item "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Thumbnail Cache' -ScriptBlock {
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Font Cache' -ScriptBlock {
    Stop-Service FontCache -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache-*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service FontCache -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Recycle Bin' -ScriptBlock {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'IE/Edge Legacy Cache' -ScriptBlock {
    Start-Process 'RunDll32.exe' -ArgumentList 'InetCpl.cpl,ClearMyTracksByProcess 255' -Wait
}

# === Browser Caches ===
Write-Host "`n[ Browser Caches ]" -ForegroundColor Yellow

$total += Invoke-CleanStep -Label 'Chrome Cache' -ScriptBlock {
    Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Edge Cache' -ScriptBlock {
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Firefox Cache' -ScriptBlock {
    Remove-Item "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Brave Cache' -ScriptBlock {
    Remove-Item "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Opera Cache' -ScriptBlock {
    Remove-Item "$env:APPDATA\Opera Software\Opera Stable\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# === Crash Dumps & Error Reports ===
Write-Host "`n[ Crash Dumps & Error Reports ]" -ForegroundColor Yellow

$total += Invoke-CleanStep -Label 'User Crash Dumps' -ScriptBlock {
    Remove-Item "$env:LOCALAPPDATA\CrashDumps\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Windows Minidumps' -ScriptBlock {
    Remove-Item "$env:SystemRoot\Minidump\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Windows Error Reports' -ScriptBlock {
    Remove-Item "$env:ProgramData\Microsoft\Windows\WER\ReportArchive\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# === Windows Update ===
Write-Host "`n[ Windows Update ]" -ForegroundColor Yellow

$total += Invoke-CleanStep -Label 'Update Download Cache' -ScriptBlock {
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Delivery Optimization Cache' -ScriptBlock {
    Stop-Service DoSvc -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service DoSvc -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Windows Setup & CBS Logs' -ScriptBlock {
    Remove-Item "$env:SystemRoot\Logs\CBS\*" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\Logs\DISM\*" -Force -ErrorAction SilentlyContinue
}

# Windows.old can be 15-30 GB on upgraded machines; some protected files may survive.
# For guaranteed full removal configure cleanmgr /sageset:1 with "Previous Windows installation(s)".
$total += Invoke-CleanStep -Label 'Windows.old (upgrade remnant)' -ScriptBlock {
    if (Test-Path "$env:SystemDrive\Windows.old") {
        Remove-Item "$env:SystemDrive\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# === Application Caches ===
Write-Host "`n[ Application Caches ]" -ForegroundColor Yellow

$total += Invoke-CleanStep -Label 'Microsoft Teams Cache' -ScriptBlock {
    Remove-Item "$env:APPDATA\Microsoft\Teams\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Microsoft\Teams\blob_storage\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Microsoft\Teams\databases\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Microsoft\Teams\GPUCache\*" -Recurse -Force -ErrorAction SilentlyContinue
}

$total += Invoke-CleanStep -Label 'Microsoft Office Cache' -ScriptBlock {
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Office\*\OfficeFileCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\Microsoft\Office\Recent\*" -Force -ErrorAction SilentlyContinue
}

# === Recent Documents & Jump Lists ===
Write-Host "`n[ Recent Documents & Jump Lists ]" -ForegroundColor Yellow

$total += Invoke-CleanStep -Label 'Recent Documents & Jump Lists' -ScriptBlock {
    # Recurse covers AutomaticDestinations and CustomDestinations subdirectories
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# === Disk Cleanup ===
Write-Host "`n[ Disk Cleanup ]" -ForegroundColor Yellow
# One-time setup required: run cleanmgr /sageset:1 to configure categories
$total += Invoke-CleanStep -Label 'cleanmgr /sagerun:1' -ScriptBlock {
    Start-Process 'cleanmgr.exe' -ArgumentList '/sagerun:1' -Wait
}

# === DISM & SFC (no space tracking — runtime too long for meaningful delta) ===
Write-Host "`n[ System Repair — no space tracking ]" -ForegroundColor Yellow

# WARNING: DISM can take 10-30 minutes and shows no progress (output suppressed).
# As long as DISM.exe + Dismhost.exe appear in Task Manager, it is working.
# Comment out if you don't need system repair:
if ($WhatIfPreference) {
    Write-Host '  ? DISM RestoreHealth — would run (dry run)' -ForegroundColor DarkCyan
    Write-Host '  ? SFC scan — would run (dry run)' -ForegroundColor DarkCyan
} else {
    Write-Host '  → DISM RestoreHealth...' -ForegroundColor DarkGray
    DISM /Online /Cleanup-Image /RestoreHealth | Out-Null

    Write-Host '  → SFC scan...' -ForegroundColor DarkGray
    sfc /scannow | Out-Null
}

# Commented out: /ResetBase permanently removes Update rollback points — opt-in only
# DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase

# === Event Logs ===
Write-Host "`n[ Event Logs ]" -ForegroundColor Yellow

$total += Invoke-CleanStep -Label 'All Event Logs' -ScriptBlock {
    Get-WinEvent -ListLog * | Where-Object { $_.IsEnabled } | ForEach-Object {
        $logName = $_.LogName
        try {
            [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog($logName)
        } catch {
            Write-Verbose "Could not clear log '$logName': $_"
        }
    }
}

# === Disk Health ===
Write-Host "`n[ Disk Health ]" -ForegroundColor Yellow
# ReTrim sends TRIM commands to the SSD — safe on HDDs (no-op if not supported).
# Frees no disk space; shown as "nothing freed" is expected.
$total += Invoke-CleanStep -Label 'SSD TRIM' -ScriptBlock {
    Optimize-Volume -DriveLetter ($env:SystemDrive.TrimEnd(':')) -ReTrim -ErrorAction SilentlyContinue
}

# === Network ===
Write-Host "`n[ Network ]" -ForegroundColor Yellow

$null = Invoke-CleanStep -Label 'DNS Cache Flush' -ScriptBlock {
    Clear-DnsClientCache
}

if ($WhatIfPreference) {
    Write-Host '  ? TCP/IP & Winsock reset — would run (dry run)' -ForegroundColor DarkCyan
} else {
    Write-Host '  → TCP/IP & Winsock reset (reboot recommended afterward)' -ForegroundColor DarkGray
    netsh int ip reset | Out-Null
    netsh winsock reset | Out-Null
}

# === Summary ===
Write-Host "`n=========================" -ForegroundColor Cyan
if ($WhatIfPreference) {
    Write-Host 'Dry run complete — no files were deleted.' -ForegroundColor DarkYellow
} else {
    Write-Host "Total freed: $(Format-MB -Bytes $total) MB" -ForegroundColor Green
    Write-Host "Free space now: $(Format-MB -Bytes (Get-FreeSpace)) MB"
}
Write-Host '=========================' -ForegroundColor Cyan
Write-Host "`nNote: Network reset takes effect after reboot.`n" -ForegroundColor DarkYellow
