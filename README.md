# Windows-Cleaner
##### crafted for Windows 11+

A lightweight, transparent PowerShell alternative to bloated system optimization software. Designed for system administrators and power users who prefer clean code over commercial "tune-up" utilities.

## Overview

This script automates deep system maintenance using native Windows APIs and binaries. It provides real-time, per-category space tracking so you can see exactly where the junk was hiding — not just a single number at the end.

## Tools Replaced

By using this script, you eliminate the need for third-party software such as:

* **CCleaner / BleachBit**: Handles temporary files, caches, and system junk.
* **Wise Disk Cleaner**: Automates Windows Update cleanup and storage optimization.
* **Network Reset Utilities**: Replaces manual flushing of DNS and resetting of the network stack.
* **Manual System Maintenance**: Integrates SFC and DISM repair cycles into a single workflow.

## Features

* **Per-Category Space Tracking**: Freed megabytes are measured and reported for every individual cleanup step, not just a total at the end.
* **System Repair**: Automates `sfc /scannow` and `DISM RestoreHealth` for OS integrity checks.
* **Advanced Cache Removal**: Clears Windows Update Distribution, Prefetch, Thumbnail, and IE/Edge Legacy caches.
* **Network Optimization**: Flushes DNS and resets Winsock/TCP stacks.
* **Structured Output**: Color-coded console output — green for freed space, gray for skipped steps.

## Usage

1. Open PowerShell as **Administrator** (`Win + X` → Terminal/PowerShell as Administrator).
2. Run the script: `.\windows-cleaner.ps1`
3. Restart your computer to finalize network and system repairs.

> **Note — cleanmgr:** The `cleanmgr /sagerun:1` step requires a one-time manual configuration. Run `cleanmgr /sageset:1` first to select which categories Disk Cleanup should handle. Without this, the step will silently do nothing.

## Warning

**FOR ADVANCED USERS ONLY.** This script performs aggressive system operations:

* **DISM RestoreHealth**: This is the slowest step and can take **10–30 minutes** with no visible progress (output is suppressed). The process is working as long as `DISM.exe` and `Dismhost.exe` appear in Task Manager. Do not cancel it. If you don't need system repair, comment out the DISM and SFC lines:
  ```powershell
  # DISM /Online /Cleanup-Image /RestoreHealth | Out-Null
  # sfc /scannow | Out-Null
  ```
* **Event Logs**: Clears all logs — may hinder troubleshooting of recent system errors.
* **Network Reset**: Drops active connections immediately; reboot required afterward.
* **Update Rollbacks**: Cleaning SoftwareDistribution may prevent uninstallation of recently applied Windows Updates.
* **ResetBase**: The `/ResetBase` flag is intentionally commented out. It removes all Update rollback points permanently — only uncomment if you know what you're doing.

---

## Changelog

### v2.0 (now pubic 4 all)
* **Per-category space tracking** via `Run-Step` helper function — each cleanup stage now reports freed MB individually.
* **Deprecated API replaced**: `Get-EventLog` (removed in PS 7+) replaced with `Get-WinEvent` + `EventLogSession.GlobalSession.ClearLog()`.
* **DISM/SFC excluded from space tracking** — their runtime is too long for a meaningful before/after delta; reported separately.
* **`/ResetBase` commented out by default** — was previously active, now opt-in with a clear warning.
* **`netsh` commands split to separate lines** — avoids edge-case failures when chained with semicolons in certain PS versions.
* **`#Requires -RunAsAdministrator`** added — script exits immediately with a clear error if not run as Admin.
* Structured, color-coded console output (green / gray / yellow sections).

### v1.0 (was privat)
* Initial release.
* Single total space delta (before/after entire script).
* Combined PowerShell cmdlets and CMD binaries in one block.

---

*Developed by Volkan — No Ads. No Telemetry. No Bullshit.*
