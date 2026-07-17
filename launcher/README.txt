PLUGCADE 0.4 ALPHA
==================

Plugcade is a tiny offline launcher for user-supplied games. It includes no
games, ROMs, disc images, BIOS files, emulator binaries, or license keys.

THE EASY START
--------------
1. Put this entire folder on a computer or USB drive.
2. Double-click START_PLUGCADE.bat (or Plugcade.hta).
3. First run opens the grown-up setup assistant.
4. Put each portable emulator folder anywhere inside Emulators\SYSTEM.
   Plugcade searches two folders deep and ignores setup/updater programs.
5. Put games in the matching DROP_GAMES_HERE\SYSTEM folder, or try
   DROP_GAMES_HERE\_SMART_INBOX for files with an unambiguous format.
6. Click IMPORT NOW. Plugcade COPIES safely and keeps every original.
7. Finish setup to make KID MODE the normal play screen.

WINDOWS 98 / ME EXPERIMENTAL START
----------------------------------
START_WINDOWS_98_EXPERIMENTAL.BAT avoids newer batch syntax. It still requires
the computer's Internet Explorer HTA engine and Windows Script Host. This is an
experimental bridge, not a compatibility promise; use Core on a copy and report
the exact Windows/IE/WSH versions that work or fail.

AUTOMATION WITHOUT BAD GUESSES
------------------------------
By default, Plugcade checks the drop folders every time it starts. It imports
new items, skips existing copies, never overwrites a different file, and logs
anything that needs a grown-up decision.

Smart Inbox can identify formats such as .nes, .gba or .z64. Ambiguous formats
such as .bin, .rom, .iso and .cue need a named system folder. This prevents a
Genesis .bin from silently becoming an Atari game, for example.

ALREADY HAVE AN ORGANIZED COLLECTION?
-------------------------------------
Grown-up Mode offers two safe choices for a folder containing system folders
such as NES, SNES, GBA, GENESIS, PS1 or ARCADE:

  COPY A COLLECTION       Copies games into Plugcade for true USB portability.
  LINK WITHOUT COPYING    Uses games where they already live and saves space.

Linked folders are recorded in Config\sources.txt. An external computer path
will not travel with the USB. Plugcade only reads the selected folder and its
immediate system folders; it never scans the whole computer.

KID MODE
--------
Kid Mode is on by default after setup. It hides grown-up tools and provides:

  LEFT / RIGHT / UP / DOWN = choose a game
  PAGE UP / PAGE DOWN      = move four games
  ENTER                    = play
  SPACE                    = say the game name
  H                        = open the game's help card

If Windows Speech is installed, Plugcade speaks names and help cards. Put an
optional cover.jpg, cover.png, cover.gif or cover.bmp beside a game's files.
Put simple instructions in help.txt for a completely offline help card.

Kid Mode is simpler navigation, not a security boundary or parental control.
A grown-up should still configure Windows accounts and content.

EMULATOR ADAPTERS
-----------------
Each enabled system has an Emulators\SYSTEM folder. Put the emulator EXE there
directly or leave it inside its normal portable subfolder. Plugcade looks two
folders deep, scores likely launchers and ignores setup, uninstall, updater,
crash-report and redistributable programs.

For exact control, add Emulators\SYSTEM\emulator.ini:

  run=folder\emulator.exe
  args="%ROM%"

Available tokens:

  %ROM%         complete game-file path
  %ROOT%        Plugcade folder path
  %SAVES%       per-system saves folder
  %GAME_SAVES%  stable per-game save folder
  %GAME_DIR%    folder containing the game
  %ID%          stable game ID
  %TITLE%       display title

DOS uses a compatible DOSBox or DOSBox-X build from Emulators\DOS. Exact
emulator and Windows compatibility must be tested on the computer being used.

DISC IMAGES
-----------
Loose .iso and .chd files can be imported where supported. Plugcade reads CUE
descriptors and copies their named track files as one game. CCD/IMG/SUB and
MDS/MDF companions are also grouped when supported. A missing track is reported
instead of being ignored.

DOS AND PORTABLE SAVES
----------------------
Every game receives Saves\SYSTEM\stable-game-id. Emulators can use the
%GAME_SAVES% token. DOS games run from a writable copy under their save folder,
leaving Library as the clean master. DOS CD games receive a portable CDrive.

Plugcade can make one dated save backup per day and offers BACK UP SAVES NOW.
It keeps the newest three Plugcade-created save backups. Automatic backup skips
a Saves folder larger than 256 MB to avoid silently filling a small USB; a
manual backup can still be confirmed. This protects files that compatible
emulators actually write, but Plugcade cannot force every third-party emulator
to support timed savestates.

PLAIN-TEXT RECORDS
------------------
Config\games.tsv is the portable catalogue. Config\recent.tsv records launches.
Logs\plugcade.log records imports, backups and failures. No database, account or
internet connection is required.

AI HELP
-------
Core does not watch the screen, use the internet, or send child data anywhere.
Offline help.txt cards work now. Any future AI helper belongs only in a newer
edition with grown-up consent, preview, no background recording and a safe
server-side key proxy. Never put an API key in this launcher.

SAFETY
------
Plugcade never deletes or moves source games, never downloads copyrighted game
content, and never overwrites a conflicting library file. This remains an alpha
until each claimed Windows edition passes real VM and hardware tests. Keep
another copy of important games and saves.
