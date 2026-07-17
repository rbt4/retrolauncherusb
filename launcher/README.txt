PLUGCADE 0.2 ALPHA
==================

Plugcade is an offline launcher for user-supplied games. It includes no games,
ROMs, disc images, BIOS files, emulator binaries, or license keys.

QUICK START
-----------
1. Put this entire folder on a computer or USB drive.
2. Add a compatible DOS emulator to Emulators\DOS:
      dosbox-x.exe  OR  dosbox.exe
3. Add a compatible GBA emulator to Emulators\GBA:
      mGBA.exe  OR  VisualBoyAdvance.exe
4. Put your legally obtained content into:
      DROP_GAMES_HERE\DOS\One Folder Per Game
      DROP_GAMES_HERE\GBA\game.gba
      DROP_GAMES_HERE\CD-ROM\One Folder Per Game
5. Run START_PLUGCADE.bat or double-click Plugcade.hta.
6. Click IMPORT GAMES. Plugcade COPIES files; it does not delete originals.

DOS GAMES
---------
Keep each DOS game in its own folder. If Plugcade finds exactly one plausible
EXE, COM, or BAT file, it uses it. If several exist, Plugcade asks once for the
exact filename and saves it in game.ini.

GBA GAMES
---------
Loose .gba files work. ZIP support depends on the selected emulator and is not
guaranteed in this alpha.

CD-ROM IMAGES
-------------
This alpha supports DOS CD-ROM images through DOSBox/DOSBox-X. It does not
promise automatic support for native Windows 95/98 CD games. Keep CUE/BIN sets
together in one folder and select the DOS program to run when prompted.

COMPATIBILITY
-------------
The graphical launcher uses Windows HTML Applications (HTA/JScript). The core
is intentionally written with old JScript syntax. Actual operating-system
support depends on the included emulator builds and still requires VM/hardware
testing before release labels are considered final.

This is an alpha for architecture and real-world testing. Keep backups of all
game content and saves.
