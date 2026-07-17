PORTABLE EMULATORS GO HERE
==========================

Open the folder for a system and place its compatible portable emulator there.
You may keep the emulator inside its normal unzipped folder. Plugcade searches
two folders deep for a likely EXE and ignores installers and updaters.

For exact control, create emulator.ini inside Emulators\SYSTEM:

  run=folder\emulator.exe
  args="%ROM%"

Extra tokens: %ROOT%, %SAVES%, %GAME_SAVES%, %GAME_DIR%, %ID%, %TITLE%.
Plugcade does not include or download emulators, BIOS files or games.
