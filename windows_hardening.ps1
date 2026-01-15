# Windows Security Hardening Script with Interactive Menu
# Description: This script allows users to harden or restore Windows security settings interactively.
# Run this script as Administrator.
# Updated: Jan 2026 (safer restore defaults + HKLM/HKCU WSH handling)
# Version 1.1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "This script must be run as Administrator." -ForegroundColor Red
        throw "Not running as Administrator."
    }
}

function Get-ServiceSafe([string]$Name) {
    try { return Get-Service -Name $Name -ErrorAction Stop } catch { return $null }
}

function Disable-ServiceSafe([string]$serviceName) {
    $svc = Get-ServiceSafe $serviceName
    if (-not $svc) {
        Write-Host "[!] Service not found: $serviceName (skipping)" -ForegroundColor DarkYellow
        return
    }

    Write-Host "[+] Disabling service: $serviceName" -ForegroundColor Cyan
    try {
        if ($svc.Status -ne "Stopped") {
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        }
        Set-Service -Name $serviceName -StartupType Disabled
        Write-Host "[OK] $serviceName disabled." -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to disable $serviceName: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-ServiceStartupSafe([string]$serviceName, [ValidateSet("Automatic","Manual","Disabled")] [string]$startupType) {
    $svc = Get-ServiceSafe $serviceName
    if (-not $svc) {
        Write-Host "[!] Service not found: $serviceName (skipping)" -ForegroundColor DarkYellow
        return
    }

    Write-Host "[+] Setting service startup: $serviceName -> $startupType" -ForegroundColor Cyan
    try {
        Set-Service -Name $serviceName -StartupType $startupType
        Write-Host "[OK] $serviceName startup set to $startupType." -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to set startup for $serviceName: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-ServiceSafe([string]$serviceName) {
    $svc = Get-ServiceSafe $serviceName
    if (-not $svc) { return }

    try {
        Start-Service -Name $serviceName -ErrorAction SilentlyContinue
    } catch { }
}

function Set-WSHEnabled([int]$value) {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings",
        "HKCU:\SOFTWARE\Microsoft\Windows Script Host\Settings"
    )

    foreach ($keyPath in $paths) {
        try {
            if (-not (Test-Path $keyPath)) {
                New-Item -Path $keyPath -Force | Out-Null
            }
            if ($null -eq (Get-ItemProperty -Path $keyPath -Name "Enabled" -ErrorAction SilentlyContinue)) {
                New-ItemProperty -Path $keyPath -Name "Enabled" -PropertyType DWord -Value $value -Force | Out-Null
            } else {
                Set-ItemProperty -Path $keyPath -Name "Enabled" -Value $value -Force
            }
            Write-Host "[OK] WSH: $keyPath Enabled=$value" -ForegroundColor Green
        } catch {
            Write-Host "[!] Failed WSH update at $keyPath: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Harden-System {
    Write-Host "`n=== HARDENING WINDOWS SECURITY SETTINGS ===" -ForegroundColor Yellow

    Write-Host "`n[1] Disable automatic Wi-Fi connection for public networks (manual step)." -ForegroundColor Yellow
    Write-Host "Use: Settings -> Network & Internet -> Wi-Fi -> Manage known networks -> Disable 'Connect automatically'." -ForegroundColor Gray

    Write-Host "`n[2] Disabling WebClient (WebDAV)..." -ForegroundColor Yellow
    Disable-ServiceSafe "WebClient"

    Write-Host "`n[3] Disabling Print Spooler..." -ForegroundColor Yellow
    Disable-ServiceSafe "Spooler"

    Write-Host "`n[4] Disabling Network Discovery services..." -ForegroundColor Yellow
    Disable-ServiceSafe "FDResPub"
    Disable-ServiceSafe "SSDPSRV"
    Disable-ServiceSafe "upnphost"

    Write-Host "`n[5] Disabling Windows Script Host (WSH)..." -ForegroundColor Yellow
    Set-WSHEnabled 0

    Write-Host "`n[+] Hardening complete. A restart is recommended." -ForegroundColor Cyan
}

function Restore-System {
    Write-Host "`n=== RESTORING WINDOWS SETTINGS ===" -ForegroundColor Yellow

    # More appropriate “restore defaults” for most systems:
    # WebClient is deprecated and not started by default => Manual is safer than Automatic.
    # Network discovery/UPnP/SSDP are typically Manual (often Trigger Start).
    Write-Host "`n[Restore] WebClient..." -ForegroundColor Yellow
    Set-ServiceStartupSafe "WebClient" "Manual"

    Write-Host "`n[Restore] Print Spooler..." -ForegroundColor Yellow
    Set-ServiceStartupSafe "Spooler" "Automatic"
    Start-ServiceSafe "Spooler"

    Write-Host "`n[Restore] Network Discovery services..." -ForegroundColor Yellow
    Set-ServiceStartupSafe "FDResPub" "Manual"
    Set-ServiceStartupSafe "SSDPSRV" "Manual"
    Set-ServiceStartupSafe "upnphost" "Manual"

    Write-Host "`n[Restore] Windows Script Host (WSH)..." -ForegroundColor Yellow
    Set-WSHEnabled 1

    Write-Host "`n[+] Restore complete. Some changes may require a restart." -ForegroundColor Cyan
    Write-Host "[i] Note: Enabling WSH does not guarantee the VBScript engine is installed/enabled on all Windows 11 builds." -ForegroundColor DarkGray
}

function Show-Menu {
    Clear-Host
    Write-Host "===============================================" -ForegroundColor DarkCyan
    Write-Host "   WINDOWS SECURITY HARDENING MENU" -ForegroundColor Yellow
    Write-Host "===============================================" -ForegroundColor DarkCyan
    Write-Host "1. Harden System (Disable Risky Features)"
    Write-Host "2. Restore System (Re-enable Defaults)"
    Write-Host "3. Exit"
    Write-Host "===============================================" -ForegroundColor DarkCyan
}

# --- Main ---
Assert-Admin

do {
    Show-Menu
    $choice = Read-Host "Select an option (1-3)"

    switch ($choice) {
        "1" { Harden-System }
        "2" { Restore-System }
        "3" { Write-Host "Exiting..." -ForegroundColor Gray }
        default { Write-Host "Invalid selection. Please choose 1, 2, or 3." -ForegroundColor Red }
    }

    if ($choice -ne "3") {
        Write-Host "`nPress any key to return to menu..." -ForegroundColor DarkGray
        [void][System.Console]::ReadKey($true)
    }
} while ($choice -ne "3")

Write-Host "`nScript ended." -ForegroundColor Green
