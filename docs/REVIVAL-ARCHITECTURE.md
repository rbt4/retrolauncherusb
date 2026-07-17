# Plugcade Revival Architecture

## Product definition

Plugcade is an offline-first, portable game launcher for user-supplied games from
classic computers and consoles. Core 0.3 exposes 26 platform adapters while the
owner supplies emulator builds appropriate to the actual Windows version and
hardware. It contains no commercial games, ROMs, disc images, BIOS files, or
license keys.

The public website explains the project and hosts releases. The downloaded
launcher never requires the website, an account, installation, or an internet
connection.

## Editions

| Edition | Host operating systems | Launcher | Intended emulator tier | Support level |
| --- | --- | --- | --- | --- |
| Standard | Windows 10/11, 32/64-bit | Native lightweight UI | Current compatible portable builds | Primary |
| Classic | Windows 7/8.1, 32/64-bit | Native lightweight UI | Frozen Win7-compatible builds | Primary |
| Legacy | Windows XP/Vista/2000, 32-bit | Minimal native/console UI | Frozen XP/low-end builds | Best effort |
| Retro | Windows 98/ME/NT4 | Separate minimal launcher | Explicitly tested low-end builds only | Experimental |
| DOS Boot | BIOS-bootable FreeDOS-capable PCs | Text menu | Native DOS games only | Future/experimental |

No release may claim support for an operating system until it boots, imports a
test library, launches at least one test title per advertised platform, returns
to the launcher, and preserves saves on that operating system or a representative
virtual machine.

## Shared portable folder layout

```text
PLUGCADE/
  START_PLUGCADE.*
  DROP_GAMES_HERE/
    DOS/
    GBA/
    CD-ROM/
    <enabled-platform>/
  Library/
    DOS/<game-id>/
    GBA/<game-id>/
    CD-ROM/<game-id>/
  Emulators/
    DOS/
    GBA/
    <enabled-platform>/
  Saves/
    DOS/<game-id>/
    GBA/<game-id>/
  Config/
    games.tsv
    sources.txt
    settings.ini
  Cache/
  Backups/
  Logs/
  Docs/
  Licenses/
```

All internal paths are stored relative to the Plugcade root. Linked computer
folders may use absolute paths but are clearly marked non-portable.

## Platform adapters

Core keeps system support data-driven and lightweight. Each adapter defines an
ID, display name, accepted extensions, library folder, emulator folder, save
folder, visual symbol, and launch mode. Core 0.3 includes adapters for DOS, DOS
CD-ROM, Arcade/MAME, NES, SNES, Nintendo 64, Game Boy, Game Boy Color, Game Boy
Advance, Virtual Boy, Genesis/Mega Drive, Master System, Game Gear, Sega 32X,
Sega CD, PlayStation 1, PC Engine/TurboGrafx, Atari 2600, Atari 7800, Atari Lynx,
Neo Geo Pocket, WonderSwan, ColecoVision, Intellivision, MSX, and Amiga.

An enabled adapter is not a compatibility claim. The emulator binary, BIOS,
operating system, drivers, and hardware determine whether a title can run. The
adapter gives Plugcade a predictable folder and launch contract without making
the core download enormous.

Every non-DOS adapter may use `Emulators/<id>/emulator.ini`:

```ini
run=emulator.exe
args="%ROM%"
```

`%ROM%`, `%ROOT%`, and `%SAVES%` are expanded at launch. If no configuration is
present, Core uses the first `.exe` in that system's emulator folder and passes
the game path in quotes.

## Kid Mode

Kid Mode is the default navigation experience. It shows large cover tiles and
only Play, Say, and Help actions. Arrow keys select a title, Enter launches,
Space speaks the title through Windows speech when available, and H opens the
local `help.txt` card. Importing, file browsing, platform setup, diagnostics, and
emulator configuration remain in Grown-up Mode.

Kid Mode is not a security boundary. Editions must describe it as simplified
navigation and continue to recommend Windows accounts, parental controls, and
adult supervision where appropriate.

## First-run experience

1. Detect Windows version, CPU architecture, write access, available space, and
   USB filesystem.
2. Create the shared folder layout.
3. Offer three import modes:
   - **Portable Copy**: copy selected content into `Library`; originals remain.
   - **Use in Place**: index content where it already lives; no duplicate data.
   - **Adopt**: move content into `Library` only after a preview and confirmation.
4. Accept content through:
   - the three `DROP_GAMES_HERE` folders;
   - a folder dragged onto the importer where supported;
   - paths explicitly added to `Config/sources.txt`;
   - a manually selected folder in GUI editions.
5. Build an import plan before changing files.
6. Group multi-file disc sets (`.cue` + `.bin`, `.ccd` + `.img` + `.sub`) as one
   title and prefer the descriptor file when launching.
7. Copy or index, verify file count and size, then write `games.tsv` atomically.
8. Place ambiguous and unsupported items in the report; never guess silently.
9. Offer a manually selected collection folder and match only that folder or its
   immediate system-named children; never turn this into a whole-disk scan.

## Classification rules

- `.gba` is a GBA candidate.
- `.cue`, `.iso`, `.ccd`, and `.mds` are disc-image descriptors/candidates.
- `.bin` and `.img` must be grouped with a descriptor where possible; they are
  never blindly treated as independent games.
- A DOS folder is a candidate when it contains `.exe`, `.com`, or `.bat` files.
- Archives are inspected only when the edition includes a compatible extractor.
- The importer may suggest a DOS executable, but the user must confirm it when
  multiple plausible executables exist.
- Setup, install, uninstall, configuration, patch, and update programs are
  down-ranked, not silently deleted.

## Game manifest

Each imported title has a stable ID independent of drive letter and display name.
The catalogue stores:

```text
id | platform | title | content_path | launch_target | emulator | save_path | source_mode
```

The actual on-disk format must remain readable with basic text tools. A tab-
separated catalogue plus optional per-game `game.ini` files is preferred over a
database for the Legacy and Retro editions.

## Safety rules

- Never scan an entire computer by default.
- Never delete source content.
- Never move source content without an explicit Adopt confirmation.
- Never overwrite a different file because its name matches.
- Never modify ROM or disc-image contents.
- Never download games, ROMs, BIOS files, or disc images.
- Log every import and launch failure in plain text.
- Keep saves outside game content so library updates cannot erase progress.
- Backups are versioned copies; restore always previews affected files.

## Emulator policy

Plugcade Core contains no emulator until redistribution terms and the exact
binary/OS combination are documented and tested. A Full release may bundle an
open-source emulator with its license, source offer/notice when required, version,
checksum, and upstream link. Frozen old-OS emulator versions are never silently
updated.

## Optional AI helper boundary

The Core, Legacy, Retro, and DOS Boot editions never require or include a cloud
AI helper. Offline `help.txt` cards remain the universal help format.

A future Standard-edition Help Buddy may send one manually approved screenshot
to a multimodal service such as Gemini. It must be disabled by default, require
grown-up consent, preview and redact every capture, avoid continuous recording,
delete captures after use, apply child-appropriate filtering, log usage, and use
a server-side proxy so no API key ships in the client. See
`docs/AI-HELPER-PRIVACY.md` for the detailed gate.

## Disc-image boundary

Initial support means DOS CD-ROM games launched through a compatible DOS emulator.
Native Windows CD-ROM games are not advertised as automatic because mounting
images on old Windows versions can require drivers, administrator access, or
game-specific installation. They may be added later as explicit per-game recipes.

## Website and release model

The website is a small static download page, not the launcher. It will include:

- a 20-second explanation;
- three optimized demonstrations: import, organize, and offline launch;
- a compatibility chooser;
- direct GitHub Release downloads with file size and SHA-256;
- Core and Full packages where licensing permits;
- an honest limitations section;
- source code, changelog, and issue links.

Every tagged release builds immutable ZIP packages. A compatibility matrix is
generated from the same release metadata used by the website so download labels
cannot drift from the actual packages.

## Milestones

1. Preserve v1.1 as abandoned historical source and extract regression cases.
2. Implement the shared layout, catalogue, and non-destructive importer.
3. Implement the adapter registry, Kid Mode, spoken names, cover art, and local
   help cards.
4. Build a public emulator/OS compatibility test matrix for the 26 adapters.
5. Ship Standard and Classic alpha builds with legally redistributable binaries.
6. Test and freeze a Legacy toolchain/build.
7. Prototype Retro separately; do not weaken newer editions for Win9x.
8. Prototype Help Buddy only after the privacy, safety, proxy, and cost gates.
9. Publish signed/checksummed GitHub Releases and optimized demo animations.
