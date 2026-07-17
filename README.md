# Plugcade

**Give an old computer another life.**

Plugcade is a tiny, offline-first launcher for user-supplied DOS games, Game Boy Advance ROMs, and supported DOS CD-ROM images. Put it on a computer or USB drive, add your own files, and play without installation, an account, or an internet connection.

[**Open the Plugcade website**](https://rbt4.github.io/retrolauncherusb/) · [**Download Core 0.2 Alpha**](https://rbt4.github.io/retrolauncherusb/downloads/Plugcade-Core-0.2-alpha.zip)

## Current status

Core 0.2 Alpha is the first functional revival build. It includes:

- a lightweight HTA/JScript graphical launcher;
- a safe, non-destructive import flow;
- obvious DOS, GBA, and CD-ROM drop folders;
- library scanning and search;
- DOS executable detection with per-game confirmation;
- DOSBox/DOSBox-X and mGBA/VisualBoyAdvance adapters;
- an emulator/system diagnostic;
- a minimal batch fallback;
- no bundled runtime and no network dependency.

The Core package does **not** bundle emulator binaries yet. Full releases will only bundle exact emulator versions after their licence, checksum, redistribution requirements, and advertised Windows compatibility are documented and tested.

## Quick start

1. [Download the ZIP](https://rbt4.github.io/retrolauncherusb/downloads/Plugcade-Core-0.2-alpha.zip).
2. Extract it onto a computer or USB drive.
3. Add a compatible portable DOS emulator to `Emulators\DOS`.
4. Add a compatible portable GBA emulator to `Emulators\GBA`.
5. Put legally obtained content into the matching `DROP_GAMES_HERE` folder.
6. Run `START_PLUGCADE.bat` or open `Plugcade.hta`.
7. Select **Import Games**.

Import copies content into Plugcade's library. It does not delete the original files.

## Repository map

- `launcher/` — current functional alpha source
- `web/` — public GitHub Pages website
- `docs/REVIVAL-ARCHITECTURE.md` — multi-edition design and safety rules
- `legacy/launcher-v1.1-abandoned.bat` — preserved original script
- `.github/workflows/pages.yml` — automatic website deployment

## Planned editions

| Edition | Intended Windows hosts | Status |
| --- | --- | --- |
| Standard | Windows 10/11 | Planned full package |
| Classic | Windows 7/8.1 | Planned full package |
| Legacy | XP/Vista/2000 32-bit | Research and testing |
| Retro | Windows 98/ME/NT4 | Experimental research |
| DOS Boot | Bootable FreeDOS-capable PCs | Future research |

No edition will claim operating-system support until it passes import, launch, return, and save-preservation tests on representative hardware or a virtual machine.

## Content and licensing

Plugcade contains no commercial games, ROMs, disc images, BIOS files, licence keys, or copy-protection bypasses. Users must provide content they are legally permitted to use.

Initial CD-ROM support targets DOS CD games through a compatible DOS emulator. Native Windows CD games can require installation, drivers, registry changes, or game-specific patches and are not advertised as automatically supported.

## Development

The abandoned v1.1 batch launcher was intentionally not patched in place. Its duplicated launch paths, invalid batch syntax, unreliable executable guessing, online update assumptions, and emulator-specific command errors made a clean core safer and smaller.

See [the revival architecture](docs/REVIVAL-ARCHITECTURE.md) for the current technical direction.
