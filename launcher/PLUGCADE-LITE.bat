@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
for %%D in ("DROP_GAMES_HERE" "DROP_GAMES_HERE\DOS" "DROP_GAMES_HERE\GBA" "DROP_GAMES_HERE\CD-ROM" "Library" "Library\DOS" "Library\GBA" "Library\CD-ROM" "Emulators" "Emulators\DOS" "Emulators\GBA" "Saves" "Backups" "Config" "Cache" "Logs") do if not exist "%%~D" md "%%~D"
:MENU
cls
echo ========================================================
echo                    P L U G C A D E
echo              YOUR ARCADE. ANYWHERE.
echo ========================================================
echo.
echo  1. Open DOS library
echo  2. Open GBA library
echo  3. Open CD-ROM library
echo  4. Open DROP_GAMES_HERE
echo  5. System check
echo  0. Exit
echo.
set "pick="
set /p "pick=Choose: "
if "%pick%"=="1" start "DOS games" explorer.exe "%CD%\Library\DOS"
if "%pick%"=="2" start "GBA games" explorer.exe "%CD%\Library\GBA"
if "%pick%"=="3" start "CD-ROM games" explorer.exe "%CD%\Library\CD-ROM"
if "%pick%"=="4" start "Drop games" explorer.exe "%CD%\DROP_GAMES_HERE"
if "%pick%"=="5" goto CHECK
if "%pick%"=="0" exit /b 0
goto MENU
:CHECK
cls
echo SYSTEM CHECK
echo ------------
if exist "Emulators\DOS\dosbox-x.exe" (echo [OK] DOSBox-X) else if exist "Emulators\DOS\dosbox.exe" (echo [OK] DOSBox) else (echo [MISSING] DOS emulator)
if exist "Emulators\GBA\mGBA.exe" (echo [OK] mGBA) else if exist "Emulators\GBA\VisualBoyAdvance.exe" (echo [OK] VisualBoyAdvance) else (echo [MISSING] GBA emulator)
echo.
echo This fallback intentionally provides safe folder access only.
echo Double-click Plugcade.hta for the full launcher.
pause
goto MENU
