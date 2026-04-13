# Windows-Cleaner
##### crafted for Windows 11+

A lightweight, transparent PowerShell alternative to bloated system optimization software. This script is designed for system administrators and power users who prefer clean code over commercial "tune-up" utilities.

## Overview
This script automates deep system maintenance using native Windows APIs and binaries. It provides real-time space tracking to monitor the effectiveness of each cleaning stage.

## Tools Replaced
By using this script, you eliminate the need for third-party software such as:
* **CCleaner / BleachBit**: Handles temporary files, caches, and system junk.
* **Wise Disk Cleaner**: Automates Windows Update cleanup and storage optimization.
* **Network Reset Utilities**: Replaces manual flushing of DNS and resetting of the network stack.
* **Manual System Maintenance**: Integrates SFC and DISM repair cycles into a single workflow.

## Features
* **Granular Space Tracking**: Calculates freed megabytes for every individual step.
* **System Repair**: Automates `sfc /scannow` and `DISM RestoreHealth` for OS integrity.
* **Advanced Cache Removal**: Clears Windows Update Distribution, Prefetch, and Thumbnail caches.
* **Network Optimization**: Flushes DNS and resets Winsock/TCP stacks.

## Warning
**FOR ADVANCED USERS ONLY.** This script is not a "one-click" solution for casual users. It performs aggressive system operations:
* **Event Logs**: Clears all logs, which may hinder troubleshooting of recent system errors.
* **Network Reset**: Will immediately drop active connections; a reboot is required afterward.
* **Update Rollbacks**: Cleaning the SoftwareDistribution folder may prevent the uninstallation of recently applied Windows Updates.

## Usage
1. Open PowerShell as **Administrator**.
2. Run the script: `.\windows-cleaner.ps1`
3. Restart your computer to finalize network and system repairs.

---
*Developed by Volkan — No Ads. No Telemetry. No Bullshit.*


