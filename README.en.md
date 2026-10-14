# Windows BAT Toolkit: batch scripts to fix network issues, clean temp files, remove Adobe and clean AMD GPU drivers

**English** | [Português (BR)](README.md)

![Platform](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white)
![Language](https://img.shields.io/badge/Batch-.bat-4D4D4D?logo=windowsterminal&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)
![UI language](https://img.shields.io/badge/menu%20language-PT--BR-blue)

A collection of interactive **Windows batch (.bat) scripts** for **Windows 10 and 11**. Each script targets one common problem:

- **No internet, DNS not resolving, IP not renewing:** layered network diagnosis and repair (flush DNS, renew IP, reset proxy, Winsock reset).
- **Disk full of temp files:** safe cleanup of Temp folders, Windows Update cache and browser caches.
- **Adobe Creative Cloud won't uninstall:** product removal plus leftover cleanup.
- **Black screens, crashes or driver timeouts on AMD Radeon GPUs:** driver cleanup for a clean reinstall.

Plain text, no obfuscation. Read the code before you run it.

> **Note:** the scripts' menus and messages are in **Brazilian Portuguese**. The logic is documented below, and an English UI is planned.

## Scripts

| Script | Purpose | Needs admin | Touches registry |
|---|---|---|---|
| [`network-fix.bat`](scripts/network-fix.bat) | Diagnose and fix internet, DNS, IP, proxy and Winsock problems | For fixes only | Yes (proxy, Winsock) |
| [`clean-temp.bat`](scripts/clean-temp.bat) | Free disk space by cleaning temp files and caches | Recommended | No |
| [`adobe-remover.bat`](scripts/adobe-remover.bat) | Uninstall Adobe products and remove leftovers | Yes | Yes, with `.reg` backup |
| [`amd-driver-cleaner.bat`](scripts/amd-driver-cleaner.bat) | Remove AMD display drivers for a clean reinstall | Yes | Yes, with `.reg` backup |

## Usage

1. Download the ZIP (Code > Download ZIP, or the Releases tab) and extract it.
2. Open the script in a text editor and read it.
3. Right-click the `.bat` and choose **Run as administrator**.
4. Pick a menu option. Destructive actions ask for confirmation.

Create a **system restore point** before running the heavier scripts.

## What each script does

### network-fix.bat (Windows network troubleshooting)

Tests in layers so you can tell where the failure is: IP configuration, default gateway, internet by IP (`1.1.1.1`, `8.8.8.8`), and DNS (current resolver vs. `1.1.1.1`). It also reports both WinHTTP and WinINET proxy settings.

Fixes: flush DNS, release/renew IP, reset proxy, restart physical network adapters, Winsock and TCP/IP stack reset (requires reboot), and an automatic fix that chains the safe ones and re-tests.

### clean-temp.bat (Windows temp file cleaner)

Cleans user Temp, system Temp, Windows Update download cache, Chrome/Edge/Brave/Firefox caches, the Recycle Bin (with confirmation) and runs `DISM /StartComponentCleanup`. Reports the space freed.

It deliberately does **not** touch `Prefetch`, `Minidump` or `DISM /ResetBase`. It deletes folder contents, never the folder itself, and refuses suspicious paths.

### adobe-remover.bat (uninstall Adobe Creative Cloud completely)

Inventory (read-only), stop processes and services, uninstall products through their registered uninstallers (Creative Cloud last), remove services/tasks/startup entries, remove leftover folders, optionally remove user data in AppData, and remove `Software\Adobe` registry keys with a `.reg` backup.

Warning: removing the system `Adobe` folders also removes Acrobat Reader. Creative Cloud Files, Documents\Adobe and Lightroom catalogs are never touched. For Creative Cloud itself, Adobe's official Creative Cloud Cleaner Tool is the most thorough option.

### amd-driver-cleaner.bat (AMD GPU driver cleanup, lightweight DDU alternative)

Diagnostics (including display driver timeout events, ID 4101), light repair (shader caches and adapter restart), AMD Software uninstall, driver package removal from the Driver Store with `pnputil`, leftover cleanup with `.reg` backup, a Windows Update driver block toggle and a Safe Mode toggle.

It does not touch chipset or Ryzen Master components. It is **less thorough than DDU** in Safe Mode, but auditable and needs no third-party tool. On laptops, use the manufacturer's driver. If BitLocker is on, have your recovery key ready before enabling Safe Mode.

## Safety

- Plain-text scripts, no obfuscation.
- **No script downloads files or sends data.** The only network activity is `ping` and `nslookup` in `network-fix.bat`.
- PowerShell (built into Windows) is used, and admin elevation is requested through `Start-Process -Verb RunAs`.
- Destructive actions ask for confirmation, and registry changes are backed up to `.reg` first.
- Antivirus products may flag scripts that touch services, drivers and the registry. Read the code instead of disabling your antivirus.

> **Disclaimer:** use at your own risk. Scripts that change drivers, the registry and system files can cause problems if used without understanding them.

## Compatibility

- **Target:** Windows 10 and 11 (64-bit) with Windows PowerShell 5.1.
- **Tested on:** <!-- TODO: fill in after testing -->

## Credits and license

- `network-fix.bat` is based on an original script by `@rablonkk`, reviewed and extended. <!-- TODO: adjust attribution -->
- Adobe, Creative Cloud, AMD, Radeon and Adrenalin are trademarks of their respective owners. This project is **not affiliated with or endorsed by** them.
- Contributions are welcome via issues and pull requests. Keep `.bat` files with CRLF line endings (handled by `.gitattributes`).
- License: [MIT](LICENSE).