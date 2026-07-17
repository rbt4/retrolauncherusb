@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
for %%D in ("DROP_GAMES_HERE" "Library" "Emulators" "Saves" "Backups" "Config" "Cache" "Logs") do if not exist "%%~D" md "%%~D"

:MENU
cls
echo ========================================================
echo                    P L U G C A D E
echo                LIGHTWEIGHT FALLBACK
echo ========================================================
echo.
echo  1. Open game library
echo  2. Open DROP_GAMES_HERE
echo  3. Open emulator folders
echo  4. Read setup guide
echo  5. Basic system check
echo  0. Exit
echo.
set "pick="
set /p "pick=Choose: "
if "%pick%"=="1" start "Game library" explorer.exe "%CD%\Library"
if "%pick%"=="2" start "Drop games" explorer.exe "%CD%\DROP_GAMES_HERE"
if "%pick%"=="3" start "Emulators" explorer.exe "%CD%\Emulators"
if "%pick%"=="4" start "Plugcade guide" notepad.exe "%CD%\README.txt"
if "%pick%"=="5" goto CHECK
if "%pick%"=="0" exit /b 0
goto MENU

:CHECK
cls
echo BASIC SYSTEM CHECK
echo ------------------
if exist "Plugcade.hta" (echo [OK] Graphical launcher) else (echo [MISSING] Plugcade.hta)
if exist "Config\settings.ini" (echo [OK] Plugcade has completed first run) else (echo [INFO] Run Plugcade.hta once to create enabled system folders)
echo.
echo Emulator folders containing EXE files:
for /d %%S in ("Emulators\*") do if exist "%%~fS\*.exe" echo [READY] %%~nxS
echo.
echo This fallback provides safe folder access when the graphical launcher
echo cannot start. It does not launch games itself.
pause
goto MENU
