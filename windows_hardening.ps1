# Windows Security Hardening Script with Interactive Menu
# Based on recommendations from Make Tech Easier (Aug 2025)
# Author: Jannick6000
# Description: This script allows users to harden or restore Windows security settings interactively.
# Run this script as Administrator.

# --- Helper Functions ---
function Disable-ServiceSafe($serviceName) {
    Write-Host "[+] Disabling service: $serviceName" -ForegroundColor Cyan
    try {
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $serviceName -StartupType Disabled
        Write-Host "[OK] $serviceName disabled." -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to disable $serviceName: $_" -ForegroundColor Red
    }
}

function Enable-ServiceSafe($serviceName) {
    Write-Host "[+] Enabling service: $serviceName" -ForegroundColor Cyan
    try {
        Set-Service -Name $serviceName -StartupType Automatic
        Start-Service -Name $serviceName -ErrorAction SilentlyContinue
        Write-Host "[OK] $serviceName enabled." -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to enable $serviceName: $_" -ForegroundColor Red
    }
}

# --- Hardening Function ---
function Harden-System {
    Write-Host "\n=== HARDENING WINDOWS SECURITY SETTINGS ===" -ForegroundColor Yellow

    # 1. Manual Wi-Fi step
    Write-Host "\n[1] Disable automatic Wi-Fi connection for public networks (manual step)." -ForegroundColor Yellow
    Write-Host "Use: Settings -> Network & Internet -> Wi-Fi -> Manage known networks -> Disable 'Connect automatically'." -ForegroundColor Gray

    # 2. Disable WebClient
    Write-Host "\n[2] Disabling WebClient (WebDAV)..." -ForegroundColor Yellow
    Disable-ServiceSafe -serviceName "WebClient"

    # 3. Disable Print Spooler
    Write-Host "\n[3] Disabling Print Spooler..." -ForegroundColor Yellow
    Disable-ServiceSafe -serviceName "Spooler"

    # 4. Disable Network Discovery services
    Write-Host "\n[4] Disabling Network Discovery services..." -ForegroundColor Yellow
    Disable-ServiceSafe -serviceName "FDResPub"
    Disable-ServiceSafe -serviceName "SSDPSRV"
    Disable-ServiceSafe -serviceName "upnphost"

    # 5. Disable Windows Script Host
    Write-Host "\n[5] Disabling Windows Script Host (WSH)..." -ForegroundColor Yellow
    try {
        $keyPath = "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"
        if (-not (Test-Path $keyPath)) {
            New-Item -Path $keyPath -Force | Out-Null
        }
        New-ItemProperty -Path $keyPath -Name "Enabled" -PropertyType DWord -Value 0 -Force | Out-Null
        Write-Host "[OK] Windows Script Host disabled (Enabled=0)." -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to modify registry for WSH: $_" -ForegroundColor Red
    }

    Write-Host "\n[+] Hardening complete. Restart your PC for all changes to take effect." -ForegroundColor Cyan
}

# --- Restore Function ---
function Restore-System {
    Write-Host "\n=== RESTORING DEFAULT WINDOWS SETTINGS ===" -ForegroundColor Yellow

    # Restore WebClient
    Write-Host "\n[Restore] Re-enabling WebClient..." -ForegroundColor Yellow
    Enable-ServiceSafe -serviceName "WebClient"

    # Restore Print Spooler
    Write-Host "\n[Restore] Re-enabling Print Spooler..." -ForegroundColor Yellow
    Enable-ServiceSafe -serviceName "Spooler"

    # Restore Network Discovery
    Write-Host "\n[Restore] Re-enabling Network Discovery services..." -ForegroundColor Yellow
    Enable-ServiceSafe -serviceName "FDResPub"
    Enable-ServiceSafe -serviceName "SSDPSRV"
    Enable-ServiceSafe -serviceName "upnphost"

    # Restore WSH
    Write-Host "\n[Restore] Re-enabling Windows Script Host (WSH)..." -ForegroundColor Yellow
    try {
        $keyPath = "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"
        if (-not (Test-Path $keyPath)) {
            New-Item -Path $keyPath -Force | Out-Null
        }
        Set-ItemProperty -Path $keyPath -Name "Enabled" -Value 1 -Force
        Write-Host "[OK] Windows Script Host re-enabled (Enabled=1)." -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to modify registry for WSH: $_" -ForegroundColor Red
    }

    Write-Host "\n[+] Restore complete. Some changes may require a restart." -ForegroundColor Cyan
}

# --- Interactive Menu ---
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

# --- Menu Loop ---
do {
    Show-Menu
    $choice = Read-Host "Select an option (1-3)"

    switch ($choice) {
        1 { Harden-System }
        2 { Restore-System }
        3 { Write-Host "Exiting..." -ForegroundColor Gray }
        default { Write-Host "Invalid selection. Please choose 1, 2, or 3." -ForegroundColor Red }
    }

    if ($choice -ne 3) {
        Write-Host "\nPress any key to return to menu..." -ForegroundColor DarkGray
        [void][System.Console]::ReadKey($true)
    }
} while ($choice -ne 3)

Write-Host "\nScript ended. Stay secure!" -ForegroundColor Green
