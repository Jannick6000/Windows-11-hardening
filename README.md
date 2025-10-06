# Windows-11-hardening

## Overview
This PowerShell script provides an **interactive menu** to harden or restore your Windows system by toggling several optional features that can be exploited by attackers. It is based on recommendations from Make Tech Easier (August 2025).

The script allows you to:
- **Harden System:** Disable unnecessary or risky Windows features.
- **Restore System:** Re-enable those features to their default state.

---

## ⚙️ Features Managed
| Feature | Harden Action | Restore Action |
|----------|----------------|----------------|
| **WebClient (WebDAV)** | Disabled | Re-enabled |
| **Print Spooler** | Disabled | Re-enabled |
| **Network Discovery** | Disabled | Re-enabled |
| **Windows Script Host (WSH)** | Disabled via Registry | Re-enabled via Registry |
| **Automatic Wi-Fi Connection** | Manual Step (user must disable manually) | Manual Step |

---

## 🚀 Usage Instructions

### 1. Run as Administrator
Right-click PowerShell and choose **“Run as Administrator.”**

### 2. Allow Script Execution (if blocked)
If you see an error about execution policies, run this command first:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
```

### 3. Run the Script
Navigate to the folder where the script is saved and run:
```powershell
./Windows-Security-Hardening.ps1
```

### 4. Use the Menu
When prompted:
- Choose **1** to harden the system.
- Choose **2** to restore defaults.
- Choose **3** to exit.

You can re-run the script anytime to toggle between hardened and restored configurations.

---

## ⚠️ Notes
- Some changes require a **system restart** to take full effect.
- Disabling Windows Script Host may break older automation scripts or legacy installers.
- If printing stops working, run the script again and select **Restore System**.

---

## ✅ Recommended Use
This script is ideal for:
- Home or personal PCs that don’t use network shares or printers.
- Public/shared systems where extra hardening is desired.
- IT administrators who want a quick toggle for secure configurations.

---

**Date:** august 2025  
**Version:** 1.0

