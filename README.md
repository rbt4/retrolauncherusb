# Plugcade

**Give an old computer another life.**

Plugcade is a tiny, offline-first launcher for user-supplied classic computer and console games. Put it on a computer or USB drive, add your own files, and play without installation, an account, or a required internet connection.

[**Open the Plugcade website**](https://rbt4.github.io/retrolauncherusb/) · [**Download Core 0.3 Alpha**](https://rbt4.github.io/retrolauncherusb/downloads/Plugcade-Core-0.3-alpha.zip) · [**Support it on Ko-fi**](https://ko-fi.com/rbt4dev)

## Core 0.3 Alpha

- default Kid Mode with large cover tiles and minimal controls;
- arrow-key navigation, spoken game names through Windows speech when available, and local `help.txt` cards;
- Grown-up Mode for importing, searching, diagnostics, and system selection;
- 26 configurable adapters spanning DOS, Arcade/MAME, Nintendo, Sega, PlayStation 1, Atari, NEC, SNK, Bandai, Coleco, Intellivision, MSX, and Amiga;
- an existing-collection importer that recognizes system-named folders without scanning the whole computer;
- optional `cover.jpg`, `cover.png`, `cover.gif`, or `cover.bmp` artwork;
- per-system emulator folders and plain-text `emulator.ini` launch arguments;
- safe imports that copy content and never delete the originals;
- a minimal batch fallback;
- no bundled games, emulator binaries, runtime, or required network service.

An enabled adapter is not a claim that every computer can emulate that system. Actual support depends on the Windows version, CPU/GPU, emulator build, drivers, and any legally required user-supplied BIOS.

## Quick start

1. [Download Core 0.3 Alpha](https://rbt4.github.io/retrolauncherusb/downloads/Plugcade-Core-0.3-alpha.zip).
2. Extract it onto a computer or USB drive.
3. Open `Plugcade.hta` or `START_PLUGCADE.bat`.
4. Switch to **Grown-up Mode** and choose the systems you need.
5. Add compatible portable emulator executables to the matching `Emulators\SYSTEM` folders.
6. Add legally obtained game files to `DROP_GAMES_HERE\SYSTEM`, or choose **Add Existing Collection**.
7. Import, then return to Kid Mode.

See [the launcher guide](launcher/README.txt) and [platform adapter list](launcher/PLATFORMS.txt).

## Kid Mode and Help Buddy

Kid Mode is simple navigation, not a security boundary or replacement for Windows parental controls. The current help system is completely local.

A future optional Gemini-based Help Buddy is a separate Standard-edition design track. It will not be enabled by default, continuously watch a screen, place an API key in the launcher, or silently upload a child's data. Read the [privacy-first AI helper design](docs/AI-HELPER-PRIVACY.md).

## Repository map

- `launcher/` — current functional alpha source
- `web/` — public GitHub Pages website
- `docs/REVIVAL-ARCHITECTURE.md` — multi-edition architecture and safety rules
- `docs/AI-HELPER-PRIVACY.md` — AI helper privacy gate
- `legacy/launcher-v1.1-abandoned.bat` — preserved original script
- `.github/workflows/pages.yml` — automatic validation, packaging, checksum, and deployment

## Planned editions

| Edition | Intended Windows hosts | Status |
| --- | --- | --- |
| Core | Varies by supplied emulator | 0.3 Alpha |
| Standard | Windows 10/11 | Planned full package |
| Classic | Windows 7/8.1 | Planned full package |
| Legacy | XP/Vista/2000 32-bit | Research and testing |
| Retro | Windows 98/ME/NT4 | Experimental research |
| DOS Boot | Bootable FreeDOS-capable PCs | Future research |

No edition will claim operating-system support until it passes import, launch, return, and save-preservation tests on representative hardware or a virtual machine.

## Content and licensing

Plugcade contains no commercial games, ROMs, disc images, BIOS files, licence keys, or copy-protection bypasses. Users must provide content they are legally permitted to use.

The project is developed in public with AI-assisted implementation and human-directed product decisions. If it gives useful life to an old machine, [Ko-fi support](https://ko-fi.com/rbt4dev) helps fund testing hardware, hosting, and development tools—without popups or locked features.
