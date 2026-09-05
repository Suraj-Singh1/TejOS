<div align="center">
  <h1>🚀 TejOS</h1>
  <p><b>Automated Lightweight Windows 11 Custom ISO Builder</b></p>
  <p><i>Windows 11 Debloat • TPM 2.0 & Secure Boot Bypass • Bloatware Removal • Zero-Touch Unattended Install</i></p>
  <p><b>An open-source tiny11 alternative — built with PowerShell + DISM</b></p>

  <p>
    <img src="https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell" />
    <img src="https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 11" />
  
  </p>

  <p>
    <a href="https://t.me/TejOS11"><img src="https://img.shields.io/badge/Telegram-Join%20the%20Community-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram Group" /></a>
  </p>
  <p><sub>Questions, hardware reports, or suggestions for what TejOS should support next? Drop them in the group.</sub></p>
</div>

---

## 🌟 What Is TejOS?

**TejOS is a fully automated PowerShell script that builds a debloated, optimized, lightweight Windows 11 custom ISO from Microsoft's official installation media.** If you've been searching for a **tiny11 alternative**, a **Windows 11 debloater**, or a way to build your own **Windows 11 lite ISO** without downloading a mystery file from a random site, this is that tool.

Using offline DISM servicing, TejOS **removes Windows 11 bloatware**, disables telemetry, aggressively reduces the **WinSxS component store**, **bypasses the TPM 2.0 / Secure Boot / CPU checks** via offline registry edits, and injects an `autounattend.xml` into the image for a **fully unattended ("zero-touch") Windows 11 install** — a local account is created automatically, no Microsoft account required, no OOBE questionnaires.

The output: an ultra-light **~2.7 GB Windows 11 ISO** (with ESD compression) that installs itself, boots fast, and runs on **old, low-end, and officially unsupported hardware** — 15-year-old PCs included.

> ⚠️ **Never download prebuilt "Windows 11 Lite ISO" files from random websites.** They are unofficial, unauditable, and a common malware vector. TejOS builds the same result **from your own official Microsoft ISO** — every line of the build is open source and runs 100% offline on your machine.

---

## ⚡ Key Features

- 🧹 **One-command Windows 11 debloat** — strips bloatware, telemetry services, background tasks, and preinstalled apps at the image level, not after install
- 🔓 **Bypass TPM 2.0, Secure Boot & RAM/CPU requirements** — install Windows 11 on unsupported and legacy hardware via offline registry edits baked into the image
- 🪶 **Aggressive WinSxS reduction** — component store significantly reduced (making the OS non-serviceable, but drastically smaller)
- 🤖 **Zero-touch unattended install** — built-in `autounattend.xml` handles the entire setup: local admin account, no Microsoft account required, no OOBE prompts
- 🗜️ **ESD / LZMS compression** — final ISO shrinks to ~2.7 GB (requires significant CPU/RAM during build)
- 🧰 **100% offline, 100% open source** — PowerShell + DISM only; no binaries shipped, nothing downloaded, nothing uploaded
- 🎚️ **Four tiers** — from safe (Full) to surgical (Nano) to extreme (Micro)

---

## 📊 The Four Tiers of TejOS

| Version | Target Audience | What It Does | Status |
| :--- | :--- | :--- | :--- |
| **TejOS Full** | General users | Removes heavy telemetry & tracking; keeps Defender, Edge, Store, and Windows Update intact. | *Coming soon* |
| **TejOS Lite** | Gamers & power users | Removes Edge and OneDrive, trims background services, keeps Windows Update functional. | *Coming soon* |
| **TejOS Nano** | **Old hardware & VMs** | **The Shredder. Aggressively strips WinSxS, removes Windows Update/Defender entirely, bypasses all hardware checks.** | **🟢 Available now!** |
| **TejOS Micro** | Kiosks & retro builds | Maximum strip-down: removes the network stack and print spooler. Tiny RAM footprint. | *Coming soon* |

---

## 🔮 Tested on the Cutting Edge: Windows 11 Insider Preview

The current TejOS Nano release was built and validated specifically against **Windows 11 Insider Preview build 29648.1000**. It has **not** been tested against other ISOs — earlier builds, other channels, or stable releases — so treat anything outside that one build as unverified for now.

Which version(s) TejOS supports next isn't locked in yet. Rather than guess, we're going by what the community actually wants and reports back — so if you try Nano against a different ISO (working or not), or have an opinion on what should be supported next, share it in the [Telegram group](https://t.me/TejOS11). Future tiers and version support will be shaped by that feedback.

---

## ⚡ TejOS Nano: What Works & What Doesn't

TejOS Nano gets its speed by surgically removing large portions of the operating system at the image level. Some things are gone by design.

### ✅ What Works Perfectly
- **General computing:** web browsing, office work, media playback.
- **Third-party software:** Steam, Discord, Chrome, Brave, Adobe, etc.
- **Basic hardware:** keyboards, mice, and universal display drivers work out of the box.
- **Local accounts:** no forced Microsoft account sign-in, ever.

### ❌ What's Removed (And the Alternatives)
- **Windows Defender (removed)** → zero built-in antivirus for maximum CPU headroom. If you need real-time protection, install a lightweight third-party engine like **Bitdefender Free**, **Kaspersky Free**, or **Avira**.
- **Windows Update (removed)** → Nano is a **non-serviceable OS by design**. WinSxS is aggressively stripped, so future updates mean building a fresh TejOS ISO — the honest trade for a minimal component store. This is the same tradeoff as tiny11 Core.
- **Microsoft Edge & OneDrive (removed)** → use **Brave**/Chrome and Google Drive/Dropbox.

### ⚠️ Important Note on Drivers
To keep the ISO tiny, Nano slims the Microsoft Driver Store down to essential universal drivers.
- **Fact:** even a completely unmodified official Windows 11 ISO offers no guarantee that your specific hardware drivers work immediately after install.
- **The fix:** after installing TejOS, download drivers from your motherboard/laptop manufacturer, or use **Snappy Driver Installer** or **IObit Driver Booster**.

---

## 📋 Requirements

- Windows 10 or 11 host, **PowerShell running as Administrator**
- An **official Windows 11 ISO** from Microsoft (any edition, including Insider Preview)
- ~20 GB free disk space · 8 GB RAM minimum (12 GB if using `-ESD` compression)
- A USB stick (8 GB+) and [Rufus](https://rufus.ie/)
- ⚠️ **Antivirus Temporarily Disabled**: You MUST temporarily disable Windows Defender Real-Time Protection and Tamper Protection (or your third-party antivirus) before running the script. Antivirus engines will aggressively lock the temporary WIM files during the build process, causing the script to crash.

---

## 🛠️ Build Your Custom Windows 11 ISO (Step by Step)

1. **Download the ISO:** get your preferred Windows 11 ISO (e.g., Insider Preview 29648.1000) from Microsoft.
2. **Mount it:** right-click the `.iso` → **Mount**, and note the drive letter (e.g., `E:\`).
3. **Open PowerShell as Administrator** and `cd` into the TejOS folder.
4. **Allow the script to run.** Windows blocks unsigned scripts by default, so lift that restriction for this one session:
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force
    ```
    `-Scope Process` means this only applies to the current PowerShell window — it reverts the moment you close it and never touches your system-wide execution policy.
5. **Run the builder with your flags:**
    ```powershell
    .\Build_TejOS-Nano.ps1 -ISO E -PreserveWinRE -ESD
    ```
6. **Wait:** the script extracts the WIM, performs offline registry surgery, strips WinSxS, applies compression, and outputs a bootable `TejOS-Nano.iso` into the script folder.
7. **Flash & boot:** write the ISO to USB with [Rufus](https://rufus.ie/). **Important:** when Rufus prompts you, **uncheck every "Windows User Experience" tweak** (TPM removal, local account creation, etc.) — TejOS already bakes all of that into the image via `autounattend.xml`. Applying it twice breaks the installation.

### Command-Line Parameters
- `-ISO <DriveLetter>`: skips the interactive prompt and pulls the WIM from the specified drive.
- `-PreserveWinRE`: keeps the Windows Recovery Environment (deleted by default to save space). Use this if you want recovery and troubleshooting tools available.
- `-ESD`: activates LZMS solid compression at the end of the build — ISO shrinks significantly, at the cost of heavy CPU usage and up to 12 GB of RAM.
- The currently validated reference build (Insider 29648.1000) was produced using both `-PreserveWinRE` and `-ESD`.

### 💡 What to Expect During the Build
- **Harmless Red Errors**: During the script's run, you may see a few (2 to 5) red error messages pop up in the console. **Do not worry!** This simply means a specific minor component was already removed or didn't exist in your specific ISO. The script is designed to safely skip past those errors and continue building the image.
- **Console Freezing**: If the console output suddenly stops moving and appears frozen for a long time, click inside the PowerShell window and **press the `Enter` key**. Windows sometimes enables a feature called "QuickEdit Mode" which accidentally pauses the entire script if you click inside the window.

---

## 🆚 How Does TejOS Compare? (vs. tiny11builder & Prebuilt Lite ISOs)

| | **TejOS** | tiny11builder | Prebuilt "Lite ISO" sites |
| :--- | :--- | :--- | :--- |
| Method | Offline ISO build (PowerShell + DISM) | Offline ISO build | Unknown |
| Uses your own official ISO | ✅ required | ✅ required | ❌ unknown provenance |
| TPM/Secure Boot bypass baked into the image | ✅ | ✅ | varies |
| Fully unattended install | ✅ via `autounattend.xml` | ❌ | varies |
| ESD compression option | ✅ | ✅ (recent versions) | varies |
| Multiple tiers | 4 | 1 (plus Core variant) | — |
| WinSxS aggressively stripped (non-serviceable) | ✅ (Nano only) | ✅ (Core only) | varies |
| Built against | Bleeding-edge Insider Preview (29648.1000) | Stable channel releases | Unknown |

*tiny11builder is excellent and directly inspired TejOS — see the full list of credits below. This table is about fit, not superiority: tiny11 is built and tested against stable channel releases, and in our own testing it ran into problems on Insider Preview 29648.1000 — the bleeding-edge channel TejOS is specifically built for.*

---

## ❓ FAQ

**Q: Can I install Windows 11 without TPM 2.0 or Secure Boot?**
Yes. TejOS applies the requirement bypasses directly to the offline image (registry + servicing), so the installer never enforces TPM 2.0, Secure Boot, or CPU checks. No Rufus workarounds needed.

**Q: How do I install Windows 11 on an old or unsupported PC?**
Build a TejOS Nano ISO on any working Windows machine, flash it with Rufus, and boot the old PC from USB. Installation runs unattended and skips all hardware checks.

**Q: Does this work in VirtualBox / VMware / Proxmox VMs without TPM?**
Yes — Nano is a popular choice for VMs: tiny disk footprint, no TPM requirement, fast boots.

**Q: Can I set up Windows 11 with a local account instead of a Microsoft account?**
Yes — the built-in `autounattend.xml` creates a local administrator account and skips the entire OOBE/Microsoft-account flow automatically. Unlike the `bypassnro` registry hack (which Microsoft patched in Windows 11 25H2), the `autounattend.xml` approach continues to work reliably.

**Q: Can I still get Windows Updates on TejOS Nano?**
No — Nano is non-serviceable by design (the WinSxS store is aggressively stripped). Updating means building a new ISO. The upcoming Full and Lite tiers keep Windows Update working.

**Q: Is there an open-source alternative to tiny11 for building a Windows 11 lite ISO?**
Yes — TejOS is an independent, open-source tiny11 alternative written in PowerShell. It's directly inspired by tiny11builder and tiny11-automated but adds four selectable tiers, a baked-in TPM/Secure Boot bypass, and a fully unattended `autounattend.xml` install out of the box.

**Q: What's the smallest possible Windows 11 ISO size?**
With TejOS Nano and the `-ESD` flag enabled, the output ISO is roughly **2.7 GB** — small enough to fit on an 8 GB USB stick with room to spare, and light enough to boot quickly even on aging hardware.

**Q: Is debloating Windows 11 with TejOS safe and legal?**
For personal use, yes. TejOS only modifies a copy of Windows 11 you already downloaded from Microsoft with your own license — the same model tiny11 and similar community tools use. It doesn't touch Windows activation or licensing in any way; it just removes components and injects setup automation into the image you provide.

**Q: Is TejOS safe?**
No binaries ship with TejOS. It is a readable PowerShell script that processes *your* Microsoft ISO, offline, on your machine — no downloads, no uploads, no telemetry of its own.

---

## ⭐ Support This Project

If TejOS helped you breathe new life into an old PC or build a cleaner Windows 11 install, consider:
- **Starring the repo** — it's the single biggest thing that helps other people find this project.
- **Opening an issue** for bugs, or hardware you'd like better driver support for.
- **Sharing it** wherever people ask about tiny11 alternatives, Windows 11 debloating, or installing Windows 11 on unsupported hardware.

## 🙏 Attribution & Credits
TejOS stands on the shoulders of giants. This project was built by learning, referencing, and expanding upon the incredible engineering work of these open-source projects:

* [ntdevlabs/tiny11builder](https://github.com/ntdevlabs/tiny11builder) — pioneering modern WIM component-reduction techniques.
* [kelexine/tiny11-automated](https://github.com/kelexine/tiny11-automated) — inspiration for PowerShell pipeline automation and offline WIM servicing.
* [christitustech/winutil](https://github.com/christitustech/winutil) — excellent registry telemetry tweaks and deep OS optimization logic.

Please go star their repositories!

*TejOS is an independent, unofficial project and is not affiliated with or endorsed by Microsoft. Use it with your own properly licensed Windows ISO.*

---
<div align="center">
  <i>Built for performance. Engineered for freedom.</i>
</div>
