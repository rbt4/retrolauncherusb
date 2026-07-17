PLUGCADE 0.3 ALPHA
==================

Plugcade is a tiny offline launcher for user-supplied games. It includes no
games, ROMs, disc images, BIOS files, emulator binaries, or license keys.

THE EASY START
--------------
1. Put this entire folder on a computer or USB drive.
2. Double-click Plugcade.hta or START_PLUGCADE.bat.
3. Plugcade starts in KID MODE. Click GROWN-UP MODE for setup tools.
4. Click CHOOSE SYSTEMS and keep only the systems you want.
5. Add a compatible portable emulator EXE to each matching Emulators folder.
6. Add games to the matching DROP_GAMES_HERE folder.
7. Click IMPORT DROP FOLDERS. Plugcade COPIES files and keeps originals.

ALREADY HAVE AN ORGANIZED COLLECTION?
-------------------------------------
In Grown-up Mode, click ADD EXISTING COLLECTION and select a folder containing
system folders such as NES, SNES, GBA, GENESIS, PS1 or ARCADE. Plugcade reads
only that selected folder and its immediate system folders. It does not scan
the whole computer. Originals are never deleted.

KID MODE
--------
Kid Mode is on by default. It hides setup tools and provides:

  LEFT / RIGHT / UP / DOWN = choose a game
  ENTER                     = play
  SPACE                     = say the game name
  H                         = open the game's help card

If Windows Speech is installed, Plugcade speaks names and help cards. Put an
optional cover.jpg, cover.png, cover.gif or cover.bmp beside a game's files for
a visual cover. Put simple instructions in help.txt for an offline help card.

Kid Mode is a simpler navigation mode, not a security boundary or parental
control system. A grown-up should still configure Windows accounts and content.

EMULATOR ADAPTERS
-----------------
Each enabled system has its own Emulators\SYSTEM folder. The simplest setup is
to place one compatible portable emulator EXE in that folder. Plugcade starts
the first EXE it finds and passes the game file in quotes.

For an emulator that needs special arguments, add emulator.ini:

  run=emulator.exe
  args="%ROM%"

Available tokens:

  %ROM%    complete game-file path
  %ROOT%   Plugcade folder path
  %SAVES%  per-system saves folder

DOS uses dosbox-x.exe or dosbox.exe from Emulators\DOS. Exact emulator and
operating-system compatibility must be tested for the computer being used.

DISC IMAGES
-----------
Loose .iso and .chd files can be imported where supported. Keep multi-file
CUE/BIN sets together in one folder. Plugcade will not import a loose .cue and
leave its required track files behind.

AI HELP
-------
The Core launcher does not watch the screen, use the internet, or send a child's
data anywhere. Offline help.txt cards are available now. A future optional AI
helper is designed only for newer Standard editions, with grown-up consent, a
clear capture preview, no background recording, and a server-side key proxy.
See Config\ai-helper.example.ini and the project privacy design for details.

SAFETY
------
Plugcade never deletes source games, never downloads copyrighted game content,
and never silently moves files. Keep backups of games and saves. This remains
an alpha until each claimed Windows edition passes real VM and hardware tests.
