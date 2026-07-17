@echo off
:: ========================================================================
:: Ultimate Kids Game Launcher
:: Version: 1.1
:: Repository: https://github.com/rbt4/launcher
:: ========================================================================
:: A portable game launcher for DOS, GBA, and CD-ROM games
:: Runs from USB drives with no installation required
:: Features auto-save, ZIP support, and game management
:: ========================================================================

setlocal enabledelayedexpansion
title Ultimate Kids Game Launcher
color 0A

:: Set script version
set "LAUNCHER_VERSION=1.1"

:: =================== PATH SETUP ===================
:: Set all paths to be relative to the launcher location
set "ROOT_DIR=%~dp0"
set "GAMES_DIR=%ROOT_DIR%games"
set "GBA_DIR=%ROOT_DIR%gba"
set "EMULATORS_DIR=%ROOT_DIR%emulators"
set "FAV_DIR=%ROOT_DIR%favorites"
set "SAVE_DIR=%ROOT_DIR%saves"
set "TEMP_DIR=%ROOT_DIR%temp"
set "ISO_DIR=%ROOT_DIR%iso"
set "BACKUP_DIR=%ROOT_DIR%backups"
set "LOG_DIR=%ROOT_DIR%logs"
set "TOOLS_DIR=%ROOT_DIR%tools"

:: Create required directories
if not exist "%GAMES_DIR%" mkdir "%GAMES_DIR%"
if not exist "%GBA_DIR%" mkdir "%GBA_DIR%"
if not exist "%EMULATORS_DIR%" mkdir "%EMULATORS_DIR%"
if not exist "%FAV_DIR%" mkdir "%FAV_DIR%"
if not exist "%SAVE_DIR%" mkdir "%SAVE_DIR%"
if not exist "%SAVE_DIR%\dos" mkdir "%SAVE_DIR%\dos"
if not exist "%SAVE_DIR%\gba" mkdir "%SAVE_DIR%\gba"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if not exist "%ISO_DIR%" mkdir "%ISO_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"
if not exist "%TOOLS_DIR%\JoyToKey" mkdir "%TOOLS_DIR%\JoyToKey"
if not exist "%TOOLS_DIR%\JoyToKey\Profiles" mkdir "%TOOLS_DIR%\JoyToKey\Profiles"

:: =================== VERSION TRACKING ===================
:: Create version file if it doesn't exist
set "VERSION_FILE=%ROOT_DIR%version.txt"
if not exist "%VERSION_FILE%" (
    echo %LAUNCHER_VERSION% > "%VERSION_FILE%"
)

:: =================== PLAYTIME TRACKING ===================
set "PLAYTIME_FILE=%ROOT_DIR%playtime.dat"
set "RECENT_FILE=%ROOT_DIR%recent.dat"
set "START_TIME=0"

:: =================== EMULATOR DETECTION ===================
:: Look for DOSBox-X specifically
set "DOSBOX_FOUND=false"
set "DOSBOX_PATH="

:: Check for DOSBox-X in emulators folder (might be named differently)
for %%f in ("%EMULATORS_DIR%\dosbox-x.exe" "%EMULATORS_DIR%\dosbox*.exe") do (
    if exist "%%~f" (
        set "DOSBOX_FOUND=true"
        set "DOSBOX_PATH=%%~f"
    )
)

:: Find GBA emulator - using simple approach
set "GBA_EMU_FOUND=false"
set "GBA_EMU_PATH="
set "GBA_EMU_NAME="

:: Try to find any GBA emulator (with common extensions) in the emulators folder
for %%e in (VisualBoyAdvance.exe mGBA.exe VBA.exe vbam.exe) do (
    if exist "%EMULATORS_DIR%\%%e" (
        set "GBA_EMU_FOUND=true"
        set "GBA_EMU_PATH=%EMULATORS_DIR%\%%e"
        set "GBA_EMU_NAME=%%~ne"
    )
)

:: Only if not found, look in common installation locations
if "%GBA_EMU_FOUND%"=="false" (
    for %%p in (
        "%ProgramFiles%\VisualBoyAdvance\VisualBoyAdvance.exe"
        "%ProgramFiles(x86)%\VisualBoyAdvance\VisualBoyAdvance.exe"
        "%ProgramFiles%\mGBA\mGBA.exe"
        "%ProgramFiles(x86)%\mGBA\mGBA.exe"
    ) do (
        if exist "%%~p" (
            set "GBA_EMU_FOUND=true"
            set "GBA_EMU_PATH=%%~p"
            set "GBA_EMU_NAME=%%~np"
        )
    )
)

:: Look for 7-Zip or similar unzip tool
set "UNZIP_FOUND=false"
set "UNZIP_PATH="

:: Check for 7-Zip in emulators folder
if exist "%EMULATORS_DIR%\7z.exe" (
    set "UNZIP_FOUND=true"
    set "UNZIP_PATH=%EMULATORS_DIR%\7z.exe"
) else (
    :: Check in system paths
    for %%p in (
        "%ProgramFiles%\7-Zip\7z.exe"
        "%ProgramFiles(x86)%\7-Zip\7z.exe"
        "%windir%\system32\tar.exe"
    ) do (
        if exist "%%~p" (
            set "UNZIP_FOUND=true"
            set "UNZIP_PATH=%%~p"
        )
    )
)

:: Check for JoyToKey
set "JOYTOKEY_FOUND=false"
set "JOYTOKEY_PATH="

if exist "%TOOLS_DIR%\JoyToKey\JoyToKey.exe" (
    set "JOYTOKEY_FOUND=true" 
    set "JOYTOKEY_PATH=%TOOLS_DIR%\JoyToKey\JoyToKey.exe"
)

:: =================== DOSBOX CONFIGURATION ===================
:: Create or check for DOSBox-X configuration with auto-save support
set "DOSBOX_CONF=%EMULATORS_DIR%\dosbox-x.conf"
if not exist "%DOSBOX_CONF%" (
    echo ; DOSBox-X configuration for Kids Game Launcher > "%DOSBOX_CONF%"
    echo [sdl] >> "%DOSBOX_CONF%"
    echo fullscreen=true >> "%DOSBOX_CONF%"
    echo [dosbox] >> "%DOSBOX_CONF%"
    echo captures=%SAVE_DIR%\dos\captures >> "%DOSBOX_CONF%"
    echo [autosave] >> "%DOSBOX_CONF%"
    echo autosave=true >> "%DOSBOX_CONF%"
    echo ; Saves automatically every 3 minutes >> "%DOSBOX_CONF%"
    echo autosave.interval=180 >> "%DOSBOX_CONF%"
    echo autosave.dir=%SAVE_DIR%\dos >> "%DOSBOX_CONF%"
)

:: =================== CACHE SYSTEM ===================
:: Create game cache directory if it doesn't exist
set "CACHE_DIR=%ROOT_DIR%cache"
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"

:: Game list cache files
set "DOS_CACHE=%CACHE_DIR%\dos_games.cache"
set "GBA_CACHE=%CACHE_DIR%\gba_games.cache"
set "ISO_CACHE=%CACHE_DIR%\iso_games.cache"

:: Function to check if cache is outdated
call :CheckGameCacheStatus

:: =================== ERROR RECOVERY SYSTEM ===================
:: Initialize error recovery settings
set "ERROR_LOG=%LOG_DIR%\errors.log"
set "ERROR_RECOVERY=true"

:: =================== CHECK FOR UPDATES ===================
call :CheckForUpdates

:: =================== MAIN MENU ===================
:MainMenu
cls
echo ========================================================
echo             ULTIMATE KIDS GAME LAUNCHER v%LAUNCHER_VERSION%
echo ========================================================
echo.

:: Count games from cache if available, otherwise scan
if "!CACHE_VALID!"=="true" (
    echo Loading game counts from cache...
    if exist "%DOS_CACHE%" (
        for /f "tokens=1,* delims==" %%a in ('type "%DOS_CACHE%" ^| findstr "^COUNT="') do (
            set "%%a=%%b"
        )
    ) else (
        set "TOTAL_DOS_COUNT=0"
    )
    
    if exist "%GBA_CACHE%" (
        for /f "tokens=1,* delims==" %%a in ('type "%GBA_CACHE%" ^| findstr "^COUNT="') do (
            set "%%a=%%b"
        )
    ) else (
        set "TOTAL_GBA_COUNT=0"
    )
    
    if exist "%ISO_CACHE%" (
        for /f "tokens=1,* delims==" %%a in ('type "%ISO_CACHE%" ^| findstr "^COUNT="') do (
            set "%%a=%%b"
        )
    ) else (
        set "ISO_COUNT=0"
    )
) else (
    :: Count games (including subfolders and ZIP files, but filtering non-game files)
    echo Scanning for games (this may take a moment)...
    
    set "DOS_COUNT=0"
    for /r "%GAMES_DIR%" %%f in (*.exe *.com *.bat) do (
        :: Skip common non-game files
        set "SKIP_FILE=false"
        
        :: Exclude common non-game executables by name
        for %%n in (install setup config unins remove update setup_wizard readme help register) do (
            if /i "%%~nf"=="%%n" set "SKIP_FILE=true"
        )
        
        :: Also check if name contains these strings
        echo "%%~nf" | findstr /i "install setup config unins remove update setup_ readme help register _setup" >nul
        if not errorlevel 1 set "SKIP_FILE=true"
        
        if "!SKIP_FILE!"=="false" set /a "DOS_COUNT+=1"
    )

    :: Count potential DOS games in ZIP archives
    set "DOS_ZIP_COUNT=0"
    for /r "%GAMES_DIR%" %%f in (*.zip) do (
        set "SKIP_FILE=false"
        
        :: Skip ZIPs with non-game-like names
        echo "%%~nf" | findstr /i "update patch save install setup" >nul
        if not errorlevel 1 set "SKIP_FILE=true"
        
        if "!SKIP_FILE!"=="false" set /a "DOS_ZIP_COUNT+=1"
    )

    :: Count ISO files
    set "ISO_COUNT=0"
    for /r "%ISO_DIR%" %%f in (*.iso *.bin *.cue *.img *.ccd) do (
        set /a "ISO_COUNT+=1"
    )

    set "GBA_COUNT=0"
    for /r "%GBA_DIR%" %%f in (*.gba) do (
        :: Skip if filename suggests it's not a ROM
        set "SKIP_FILE=false"
        
        :: Skip if it contains these strings
        echo "%%~nf" | findstr /i "update patch save" >nul
        if not errorlevel 1 set "SKIP_FILE=true"
        
        if "!SKIP_FILE!"=="false" set /a "GBA_COUNT+=1"
    )

    :: Count GBA games in ZIP archives
    set "GBA_ZIP_COUNT=0"
    for /r "%GBA_DIR%" %%f in (*.zip) do (
        set "SKIP_FILE=false"
        
        :: Skip ZIPs with non-game-like names
        echo "%%~nf" | findstr /i "update patch save install setup" >nul
        if not errorlevel 1 set "SKIP_FILE=true"
        
        if "!SKIP_FILE!"=="false" set /a "GBA_ZIP_COUNT+=1"
    )

    set /a "TOTAL_DOS_COUNT=%DOS_COUNT%+%DOS_ZIP_COUNT%"
    set /a "TOTAL_GBA_COUNT=%GBA_COUNT%+%GBA_ZIP_COUNT%"
    
    :: Update cache
    > "%DOS_CACHE%" echo COUNT=%TOTAL_DOS_COUNT%
    >> "%DOS_CACHE%" echo DOS_COUNT=%DOS_COUNT%
    >> "%DOS_CACHE%" echo DOS_ZIP_COUNT=%DOS_ZIP_COUNT%
    
    > "%GBA_CACHE%" echo COUNT=%TOTAL_GBA_COUNT%
    >> "%GBA_CACHE%" echo GBA_COUNT=%GBA_COUNT%
    >> "%GBA_CACHE%" echo GBA_ZIP_COUNT=%GBA_ZIP_COUNT%
    
    > "%ISO_CACHE%" echo COUNT=%ISO_COUNT%
)

echo Found %TOTAL_DOS_COUNT% DOS games (%DOS_COUNT% direct, %DOS_ZIP_COUNT% in ZIP files)
echo Found %TOTAL_GBA_COUNT% GBA ROMs (%GBA_COUNT% direct, %GBA_ZIP_COUNT% in ZIP files)
echo Found %ISO_COUNT% CD-ROM ISOs
echo.

:: Check emulator status
if "%DOSBOX_FOUND%"=="true" (
    echo DOSBox-X: READY
) else (
    echo DOSBox-X: NOT FOUND! Please add DOSBox-X.exe to your emulators folder.
)

if "%GBA_EMU_FOUND%"=="true" (
    echo GBA Emulator: READY [%GBA_EMU_NAME%]
) else (
    echo GBA Emulator: NOT FOUND! GBA games won't work.
)

if "%UNZIP_FOUND%"=="true" (
    echo ZIP Support: READY
) else (
    echo ZIP Support: LIMITED - Add 7z.exe to your emulators folder for full ZIP support
)

if "%JOYTOKEY_FOUND%"=="true" (
    echo Controller Support: READY
) else (
    echo Controller Support: NOT FOUND! Add JoyToKey.exe to your tools\JoyToKey folder.
)

echo.
echo Menu Options:
echo 1. Play DOS Games
echo 2. Play GBA Games 
echo 3. Play CD-ROM Games
echo 4. View Favorites
echo 5. Game Statistics
echo 6. Backup Manager
echo 7. Controller Setup
echo 8. Check for Updates
echo 9. Exit
echo.

set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto DOSGames
if "%choice%"=="2" goto GBAGames
if "%choice%"=="3" goto ISOGames
if "%choice%"=="4" goto Favorites
if "%choice%"=="5" goto GameStats
if "%choice%"=="6" goto BackupManager
if "%choice%"=="7" goto ControllerSetup
if "%choice%"=="8" call :CheckForUpdates
if "%choice%"=="9" goto Exit

echo Invalid choice. Press any key to continue...
pause >nul
goto MainMenu

:: =================== DOS GAMES ===================
:DOSGames
cls
echo ========================================================
echo                     DOS GAMES
echo ========================================================
echo.

if "%DOSBOX_FOUND%"=="false" (
    echo DOSBox-X is not found in your emulators folder!
    echo.
    echo To play DOS games, you need DOSBox-X.exe in:
    echo %EMULATORS_DIR%
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

:: List all DOS games (including subfolders, but filtering non-game files)
set "GAME_NUM=0"

:: First list regular executable files
for /r "%GAMES_DIR%" %%f in (*.exe *.com *.bat) do (
    :: Skip common non-game files
    set "SKIP_FILE=false"
    
    :: Exclude common non-game executables by name
    for %%n in (install setup config unins remove update setup_wizard readme help register) do (
        if /i "%%~nf"=="%%n" set "SKIP_FILE=true"
    )
    
    :: Also check if name contains these strings
    echo "%%~nf" | findstr /i "install setup config unins remove update setup_ readme help register _setup" >nul
    if not errorlevel 1 set "SKIP_FILE=true"
    
    if "!SKIP_FILE!"=="false" (
        set /a "GAME_NUM+=1"
        set "GAME_PATH[!GAME_NUM!]=%%~dpnxf"
        set "GAME_NAME[!GAME_NUM!]=%%~nf"
        set "GAME_FILE[!GAME_NUM!]=%%~nxf"
        set "GAME_DIR[!GAME_NUM!]=%%~dpf"
        set "GAME_TYPE[!GAME_NUM!]=EXE"
        
        :: Display name with subfolder if not in main games folder
        set "DISPLAY_NAME=%%~nf"
        set "REL_PATH=%%~dpf"
        set "REL_PATH=!REL_PATH:%GAMES_DIR%\=!"
        if not "!REL_PATH!"=="!GAMES_DIR!" (
            if not "!REL_PATH!"=="" (
                set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf"
            )
        )
        
        :: Check if save exists and add indicator
        set "SAVE_EXISTS="
        if exist "%SAVE_DIR%\dos\!GAME_NAME[%GAME_NUM%]!\*.sav" set "SAVE_EXISTS=[SAVE]"
        
        :: Check playtime and add indicator
        set "PLAYTIME="
        if exist "%PLAYTIME_FILE%" (
            for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%" ^| findstr /i "^!GAME_NAME[%GAME_NUM%]!="') do (
                set /a "HOURS=%%b/60"
                set /a "MINS=%%b%%60"
                if !HOURS! gtr 0 (
                    set "PLAYTIME=[!HOURS!h !MINS!m]"
                ) else (
                    set "PLAYTIME=[!MINS!m]"
                )
            )
        )
        
        echo !GAME_NUM!. !DISPLAY_NAME! !SAVE_EXISTS! !PLAYTIME!
    )
)

:: Then list ZIP files potentially containing DOS games
for /r "%GAMES_DIR%" %%f in (*.zip) do (
    set "SKIP_FILE=false"
    
    :: Skip ZIPs with non-game-like names
    echo "%%~nf" | findstr /i "update patch save install setup" >nul
    if not errorlevel 1 set "SKIP_FILE=true"
    
    if "!SKIP_FILE!"=="false" (
        set /a "GAME_NUM+=1"
        set "GAME_PATH[!GAME_NUM!]=%%~dpnxf"
        set "GAME_NAME[!GAME_NUM!]=%%~nf"
        set "GAME_FILE[!GAME_NUM!]=%%~nxf"
        set "GAME_DIR[!GAME_NUM!]=%%~dpf"
        set "GAME_TYPE[!GAME_NUM!]=ZIP"
        
        :: Display name with subfolder if not in main games folder
        set "DISPLAY_NAME=%%~nf [ZIP]"
        set "REL_PATH=%%~dpf"
        set "REL_PATH=!REL_PATH:%GAMES_DIR%\=!"
        if not "!REL_PATH!"=="!GAMES_DIR!" (
            if not "!REL_PATH!"=="" (
                set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf [ZIP]"
            )
        )
        
        :: Check if save exists and add indicator
        set "SAVE_EXISTS="
        if exist "%SAVE_DIR%\dos\!GAME_NAME[%GAME_NUM%]!\*.sav" set "SAVE_EXISTS=[SAVE]"
        
        :: Check playtime and add indicator
        set "PLAYTIME="
        if exist "%PLAYTIME_FILE%" (
            for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%" ^| findstr /i "^!GAME_NAME[%GAME_NUM%]!="') do (
                set /a "HOURS=%%b/60"
                set /a "MINS=%%b%%60"
                if !HOURS! gtr 0 (
                    set "PLAYTIME=[!HOURS!h !MINS!m]"
                ) else (
                    set "PLAYTIME=[!MINS!m]"
                )
            )
        )
        
        echo !GAME_NUM!. !DISPLAY_NAME! !SAVE_EXISTS! !PLAYTIME!
    )
)

if %GAME_NUM% equ 0 (
    echo No DOS games found in the games folder.
    echo Please add some games to: %GAMES_DIR%
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

echo.
echo 0. Return to main menu
echo F. Mark game as favorite
echo.

set /p game_choice="Enter game number to play: "

if "%game_choice%"=="0" goto MainMenu
if /i "%game_choice%"=="F" goto MarkDOSFavorite

:: Validate input
set /a game_num=%game_choice% 2>nul
if %game_num% lss 1 goto DOSGames
if %game_num% gtr %GAME_NUM% goto DOSGames

:: Start tracking playtime
call :StartTimeTracking

:: Launch the selected DOS game with DOSBox-X
cls
echo ========================================================
echo                   LAUNCHING GAME
echo ========================================================
echo.
echo Launching: !GAME_NAME[%game_num%]!
echo Path: !GAME_PATH[%game_num%]!
echo Using DOSBox-X from: %DOSBOX_PATH%
echo.

:: Start JoyToKey if it exists and has a profile
if "%JOYTOKEY_FOUND%"=="true" (
    if exist "%TOOLS_DIR%\JoyToKey\Profiles\!GAME_NAME[%game_num%]!.cfg" (
        echo Starting JoyToKey with game-specific profile...
        start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\!GAME_NAME[%game_num%]!.cfg"
    ) else if exist "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg" (
        echo Starting JoyToKey with default DOSBox profile...
        start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg"
    ) else (
        echo Starting JoyToKey with default profile...
        start "" "%JOYTOKEY_PATH%"
    )
)

:: Check if it's a ZIP file that needs extraction
if "!GAME_TYPE[%game_num%]!"=="ZIP" (
    echo Extracting game files from ZIP...
    
    :: Create temporary directory for extraction
    set "EXTRACT_DIR=%TEMP_DIR%\!GAME_NAME[%game_num%]!"
    if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!"
    mkdir "!EXTRACT_DIR!"
    
    :: Create a safe path version without special characters
    set "SAFE_PATH=!GAME_PATH[%game_num%]!"
    set "SAFE_PATH=!SAFE_PATH:&=^&!"
    set "SAFE_PATH=!SAFE_PATH:(=^(!"
    set "SAFE_PATH=!SAFE_PATH:)=^)!"
    set "SAFE_PATH=!SAFE_PATH:>=^>!"
    set "SAFE_PATH=!SAFE_PATH:<=^<!"
    set "SAFE_PATH=!SAFE_PATH:|=^|!"
    
    :: Extract ZIP file with error handling
    echo Using PowerShell to extract files...
    powershell -command "try { Expand-Archive -LiteralPath '!SAFE_PATH!' -DestinationPath '!EXTRACT_DIR!' -Force } catch { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        echo PowerShell extraction failed, trying alternate methods...
        
        :: Try 7-Zip if available
        if exist "%EMULATORS_DIR%\7z.exe" (
            "%EMULATORS_DIR%\7z.exe" x -y "!GAME_PATH[%game_num%]!" -o"!EXTRACT_DIR!" >nul
        ) else if exist "%UNZIP_PATH%" (
            "%UNZIP_PATH%" x -y "!GAME_PATH[%game_num%]!" -o"!EXTRACT_DIR!" >nul
        ) else {
            echo Unable to extract ZIP file: format not supported
            echo Please install 7-Zip in the emulators folder for better ZIP support
            goto ErrorHandler
        }
    )
    
    echo Extraction complete. Finding main executable...
    
    :: List all files for debugging
    echo Files found in extraction:
    dir /b /s "!EXTRACT_DIR!" | findstr /i "\.exe \.com \.bat"
    echo.
    
    :: Find ANY executable in the extracted folder (not just common names)
    set "FOUND_EXE=false"
    set "EXTRACT_EXE="
    set "EXTRACT_SUBDIR="
    
    :: Use a more comprehensive approach to find a suitable executable
    :: First pass: Look for .exe files in root directory that aren't common utilities
    for %%f in ("!EXTRACT_DIR!\*.exe") do (
        if "!FOUND_EXE!"=="false" (
            :: Skip known setup/utility executables
            set "UTILITY=false"
            for %%u in (setup install config unins readme help) do (
                if /i "%%~nf"=="%%u" set "UTILITY=true"
            )
            
            :: If not a utility, use it
            if "!UTILITY!"=="false" (
                set "FOUND_EXE=true"
                set "EXTRACT_EXE=%%~nxf"
                set "EXTRACT_SUBDIR=%%~dpf"
                echo Found game executable: %%~nxf in root folder
            )
        )
    )
    
    :: Second pass: Look for .exe files in any subfolder if not found yet
    if "!FOUND_EXE!"=="false" (
        for /r "!EXTRACT_DIR!" %%f in (*.exe) do (
            if "!FOUND_EXE!"=="false" (
                :: Skip known setup files
                set "UTILITY=false"
                for %%u in (setup install config unins readme help) do (
                    if /i "%%~nf"=="%%u" set "UTILITY=true"
                )
                
                :: Also check if name contains these strings
                echo "%%~nf" | findstr /i "setup install config unins readme help" >nul
                if not errorlevel 1 set "UTILITY=true"
                
                :: If not a utility, use it
                if "!UTILITY!"=="false" (
                    set "FOUND_EXE=true"
                    set "EXTRACT_EXE=%%~nxf"
                    set "EXTRACT_SUBDIR=%%~dpf"
                    echo Found game executable: %%~nxf in subfolder
                )
            )
        )
    )
    
    :: Try .com files as a last resort
    if "!FOUND_EXE!"=="false" (
        for /r "!EXTRACT_DIR!" %%f in (*.com) do (
            if "!FOUND_EXE!"=="false" (
                set "FOUND_EXE=true"
                set "EXTRACT_EXE=%%~nxf"
                set "EXTRACT_SUBDIR=%%~dpf"
                echo Found executable: %%~nxf
            )
        )
    )
    
    if "!FOUND_EXE!"=="false" (
        echo No executable found in the ZIP archive.
        echo.
        echo Files in extracted folder:
        dir /s /b "!EXTRACT_DIR!"
        echo.
        echo Press any key to return to the game list...
        pause >nul
        goto DOSGames
    )
    
    echo Auto-save is enabled. Game will auto-save every 3 minutes.
    echo Press CTRL+F4 for quick save or F9 for quick load during gameplay.
    echo.
    echo When you're done playing, the launcher will return.
    echo.
    timeout /t 3 >nul
    
    :: Create a game-specific save folder if needed
    set "GAME_SAVE_DIR=%SAVE_DIR%\dos\!GAME_NAME[%game_num%]!"
    if not exist "%GAME_SAVE_DIR%" mkdir "%GAME_SAVE_DIR%"
    
    :: Remove quotes from paths to avoid syntax errors
    set "MOUNT_PATH=!EXTRACT_SUBDIR!"
    set "MOUNT_PATH=!MOUNT_PATH:"=!"
    
    :: Check for path length limits
    set "PATH_LENGTH=0"
    set "PATH_TO_CHECK=!MOUNT_PATH!!EXTRACT_EXE!"
    for %%p in ("!PATH_TO_CHECK!") do set "PATH_LENGTH=%%~zp"
    
    if !PATH_LENGTH! gtr 240 (
        echo WARNING: Path is very long and may cause issues.
        echo Using short path names to mitigate...
        
        :: Use short path names when paths are too long
        for %%i in ("!MOUNT_PATH!") do set "MOUNT_PATH=%%~si"
        for %%i in ("!EXTRACT_EXE!") do set "EXTRACT_EXE=%%~si"
    )
    
    :: Launch DOSBox with proper command line
    call :SafeLaunch "%DOSBOX_PATH%" -conf "%DOSBOX_CONF%" -c "mount c \"!MOUNT_PATH!\"" -c "c:" -c "!EXTRACT_EXE!" -savedir "%GAME_SAVE_DIR%"
    
) else (
    :: Regular executable file
    echo Auto-save is enabled. Game will auto-save every 3 minutes.
    echo Press CTRL+F4 for quick save or F9 for quick load during gameplay.
    echo.
    echo When you're done playing, the launcher will return.
    echo.
    timeout /t 3 >nul
    
:: Create a game-specific save folder if needed
    set "GAME_SAVE_DIR=%SAVE_DIR%\dos\!GAME_NAME[%game_num%]!"
    if not exist "%GAME_SAVE_DIR%" mkdir "%GAME_SAVE_DIR%"
    
    :: Remove quotes from paths to avoid syntax errors
    set "MOUNT_PATH=!GAME_DIR[%game_num%]!"
    set "MOUNT_PATH=!MOUNT_PATH:"=!"
    set "GAME_EXEC=!GAME_FILE[%game_num%]!"
    
    :: Check for path length limits
    set "PATH_LENGTH=0"
    set "PATH_TO_CHECK=!MOUNT_PATH!!GAME_EXEC!"
    for %%p in ("!PATH_TO_CHECK!") do set "PATH_LENGTH=%%~zpn"
    
    if !PATH_LENGTH! gtr 240 (
        echo WARNING: Path is very long and may cause issues.
        echo Using short path names to mitigate...
        
        :: Use short path names when paths are too long
        for %%i in ("!MOUNT_PATH!") do set "MOUNT_PATH=%%~si"
        for %%i in ("!GAME_EXEC!") do set "GAME_EXEC=%%~sni"
    )
    
    :: Launch DOSBox with correct command line
    call :SafeLaunch "%DOSBOX_PATH%" -conf "%DOSBOX_CONF%" -c "mount c \"!MOUNT_PATH!\"" -c "c:" -c "!GAME_EXEC!" -savedir "%GAME_SAVE_DIR%"
)

:: End tracking and update playtime
call :EndTimeTracking

echo Game finished! Press any key to return to the menu...
pause >nul
goto MainMenu

:: =================== MARK DOS FAVORITE ===================
:MarkDOSFavorite
cls
echo ========================================================
echo                 MARK FAVORITE DOS GAME
echo ========================================================
echo.

echo Select a game to mark as favorite:
echo.

for /l %%i in (1,1,%GAME_NUM%) do (
    :: Display name with subfolder if not in main games folder
    set "DISPLAY_NAME=!GAME_NAME[%%i]!"
    set "REL_PATH=!GAME_DIR[%%i]!"
    set "REL_PATH=!REL_PATH:%GAMES_DIR%\=!"
    if not "!REL_PATH!"=="!GAMES_DIR!" (
        if not "!REL_PATH!"=="" (
            set "DISPLAY_NAME=[!REL_PATH:~0,-1!] !GAME_NAME[%%i]!"
        )
    )
    
    :: Add [ZIP] indicator for ZIP files
    if "!GAME_TYPE[%%i]!"=="ZIP" (
        set "DISPLAY_NAME=!DISPLAY_NAME! [ZIP]"
    )
    
    echo %%i. !DISPLAY_NAME!
)

echo.
echo 0. Return to games list
echo.

set /p fav_choice="Enter game number: "

if "%fav_choice%"=="0" goto DOSGames

:: Validate input
set /a fav_num=%fav_choice% 2>nul
if %fav_num% lss 1 goto MarkDOSFavorite
if %fav_num% gtr %GAME_NUM% goto MarkDOSFavorite

:: Add to favorites
if not exist "%FAV_DIR%\favorites.txt" (
    echo ; FAVORITES > "%FAV_DIR%\favorites.txt"
)

:: Create a link to the game in the favorites file
echo DOS:!GAME_NAME[%fav_num%]!=!GAME_PATH[%fav_num%]!>> "%FAV_DIR%\favorites.txt"

echo.
echo Game marked as favorite!
timeout /t 2 >nul
goto DOSGames

:: =================== ISO GAMES ===================
:ISOGames
cls
echo ========================================================
echo                   CD-ROM ISO GAMES
echo ========================================================
echo.

if "%DOSBOX_FOUND%"=="false" (
    echo DOSBox-X is not found in your emulators folder!
    echo.
    echo To play CD-ROM games, you need DOSBox-X.exe in:
    echo %EMULATORS_DIR%
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

:: List all ISO files
set "ISO_NUM=0"
for /r "%ISO_DIR%" %%f in (*.iso *.bin *.cue *.img *.ccd) do (
    set /a "ISO_NUM+=1"
    set "ISO_PATH[!ISO_NUM!]=%%~dpnxf"
    set "ISO_NAME[!ISO_NUM!]=%%~nf"
    set "ISO_FILE[!ISO_NUM!]=%%~nxf"
    set "ISO_DIR[!ISO_NUM!]=%%~dpf"
    set "ISO_EXT[!ISO_NUM!]=%%~xf"
    
    :: Display name with subfolder if not in main ISO folder
    set "DISPLAY_NAME=%%~nf [%%~xf]"
    set "REL_PATH=%%~dpf"
    set "REL_PATH=!REL_PATH:%ISO_DIR%\=!"
    if not "!REL_PATH!"=="!ISO_DIR!" (
        if not "!REL_PATH!"=="" (
            set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf [%%~xf]"
        )
    )
    
    :: Check if save exists and add indicator
    set "SAVE_EXISTS="
    if exist "%SAVE_DIR%\dos\!ISO_NAME[%ISO_NUM%]!\*.sav" set "SAVE_EXISTS=[SAVE]"
    
    :: Check playtime and add indicator
    set "PLAYTIME="
    if exist "%PLAYTIME_FILE%" (
        for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%" ^| findstr /i "^!ISO_NAME[%ISO_NUM%]!="') do (
            set /a "HOURS=%%b/60"
            set /a "MINS=%%b%%60"
            if !HOURS! gtr 0 (
                set "PLAYTIME=[!HOURS!h !MINS!m]"
            ) else (
                set "PLAYTIME=[!MINS!m]"
            )
        )
    )
    
    echo !ISO_NUM!. !DISPLAY_NAME! !SAVE_EXISTS! !PLAYTIME!
)

if %ISO_NUM% equ 0 (
    echo No ISO files found in the iso folder.
    echo Please add some CD-ROM images to: %ISO_DIR%
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

echo.
echo 0. Return to main menu
echo F. Mark ISO as favorite
echo.

set /p iso_choice="Enter number to play: "

if "%iso_choice%"=="0" goto MainMenu
if /i "%iso_choice%"=="F" goto MarkISOFavorite

:: Validate input
set /a iso_num=%iso_choice% 2>nul
if %iso_num% lss 1 goto ISOGames
if %iso_num% gtr %ISO_NUM% goto ISOGames

:: Start tracking playtime
call :StartTimeTracking

:: Launch the selected ISO with DOSBox-X
cls
echo ========================================================
echo                 LAUNCHING CD-ROM GAME
echo ========================================================
echo.
echo Launching: !ISO_NAME[%iso_num%]!!ISO_EXT[%iso_num%]!
echo Path: !ISO_PATH[%iso_num%]!
echo Using DOSBox-X from: %DOSBOX_PATH%
echo.
echo Auto-save is enabled. Game will auto-save every 3 minutes.
echo Press CTRL+F4 for quick save or F9 for quick load during gameplay.
echo.
echo When you're done playing, the launcher will return.
echo.
timeout /t 3 >nul

:: Start JoyToKey if it exists and has a profile
if "%JOYTOKEY_FOUND%"=="true" (
    if exist "%TOOLS_DIR%\JoyToKey\Profiles\!ISO_NAME[%iso_num%]!.cfg" (
        echo Starting JoyToKey with game-specific profile...
        start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\!ISO_NAME[%iso_num%]!.cfg"
    ) else if exist "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg" (
        echo Starting JoyToKey with default DOSBox profile...
        start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg"
    ) else (
        echo Starting JoyToKey with default profile...
        start "" "%JOYTOKEY_PATH%"
    )
)

:: Create a game-specific save folder if needed
set "ISO_SAVE_DIR=%SAVE_DIR%\dos\!ISO_NAME[%iso_num%]!"
if not exist "%ISO_SAVE_DIR%" mkdir "%ISO_SAVE_DIR%"

:: Create temporary C: drive directory if it doesn't exist
set "TEMP_C_DIR=%TEMP_DIR%\!ISO_NAME[%iso_num%]!"
if not exist "!TEMP_C_DIR!" mkdir "!TEMP_C_DIR!"

:: Remove quotes from paths to avoid syntax errors
set "ISO_CLEAN_PATH=!ISO_PATH[%iso_num%]!"
set "ISO_CLEAN_PATH=!ISO_CLEAN_PATH:"=!"

:: Determine the proper imgmount parameters based on file extension
set "ISO_TYPE=iso"
if /i "!ISO_EXT[%iso_num%]!"==".bin" set "ISO_TYPE=cue"
if /i "!ISO_EXT[%iso_num%]!"==".cue" set "ISO_TYPE=cue"
if /i "!ISO_EXT[%iso_num%]!"==".ccd" set "ISO_TYPE=cue"
if /i "!ISO_EXT[%iso_num%]!"==".img" (
    :: Check if it's a CD image or a floppy image
    for %%f in ("!ISO_PATH[%iso_num%]!") do set "FILE_SIZE=%%~zf"
    if !FILE_SIZE! gtr 2000000 (
        set "ISO_TYPE=iso"
    ) else (
        set "ISO_TYPE=floppy"
    )
)

:: Check for path length limits
set "PATH_LENGTH=0"
set "PATH_TO_CHECK=!ISO_CLEAN_PATH!"
for %%p in ("!PATH_TO_CHECK!") do set "PATH_LENGTH=%%~zp"

if !PATH_LENGTH! gtr 240 (
    echo WARNING: Path is very long and may cause issues.
    echo Using short path names to mitigate...
    
    :: Use short path names when paths are too long
    for %%i in ("!ISO_CLEAN_PATH!") do set "ISO_CLEAN_PATH=%%~si"
)

:: Mount with the appropriate type
if "!ISO_TYPE!"=="floppy" (
    call :SafeLaunch "%DOSBOX_PATH%" -conf "%DOSBOX_CONF%" -c "mount c \"!TEMP_C_DIR!\"" -c "imgmount a \"!ISO_CLEAN_PATH!\" -t !ISO_TYPE!" -c "a:" -c "dir" -savedir "%ISO_SAVE_DIR%"
) else (
    call :SafeLaunch "%DOSBOX_PATH%" -conf "%DOSBOX_CONF%" -c "mount c \"!TEMP_C_DIR!\"" -c "imgmount d \"!ISO_CLEAN_PATH!\" -t !ISO_TYPE!" -c "d:" -c "dir" -savedir "%ISO_SAVE_DIR%"
)

:: End tracking and update playtime
call :EndTimeTracking

echo Game finished! Press any key to return to the menu...
pause >nul
goto MainMenu
:: =================== MARK ISO FAVORITE ===================
:MarkISOFavorite
cls
echo ========================================================
echo                 MARK FAVORITE CD-ROM
echo ========================================================
echo.

echo Select a CD-ROM to mark as favorite:
echo.

for /l %%i in (1,1,%ISO_NUM%) do (
    :: Display name with subfolder if not in main ISO folder
    set "DISPLAY_NAME=!ISO_NAME[%%i]!"
    set "REL_PATH=!ISO_DIR[%%i]!"
    set "REL_PATH=!REL_PATH:%ISO_DIR%\=!"
    if not "!REL_PATH!"=="!ISO_DIR!" (
        if not "!REL_PATH!"=="" (
            set "DISPLAY_NAME=[!REL_PATH:~0,-1!] !ISO_NAME[%%i]!"
        )
    )
    
    echo %%i. !DISPLAY_NAME! [!ISO_EXT[%%i]!]
)

echo.
echo 0. Return to ISO list
echo.

set /p fav_choice="Enter ISO number: "

if "%fav_choice%"=="0" goto ISOGames

:: Validate input
set /a fav_num=%fav_choice% 2>nul
if %fav_num% lss 1 goto MarkISOFavorite
if %fav_num% gtr %ISO_NUM% goto MarkISOFavorite

:: Add to favorites
if not exist "%FAV_DIR%\favorites.txt" (
    echo ; FAVORITES > "%FAV_DIR%\favorites.txt"
)

:: Create a link to the ISO in the favorites file
echo ISO:!ISO_NAME[%fav_num%]!=!ISO_PATH[%fav_num%]!>> "%FAV_DIR%\favorites.txt"

echo.
echo CD-ROM marked as favorite!
timeout /t 2 >nul
goto ISOGames

:: =================== GBA GAMES ===================
:GBAGames
cls
echo ========================================================
echo                     GBA GAMES
echo ========================================================
echo.

if "%GBA_EMU_FOUND%"=="false" (
    echo No GBA emulator found!
    echo.
    echo To play GBA games, you need a GBA emulator in:
    echo %EMULATORS_DIR%
    echo.
    echo Supported emulators: VisualBoyAdvance.exe, mGBA.exe
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

:: List all GBA ROMs (including subfolders and ZIP files, filtering non-ROM files)
set "ROM_NUM=0"

:: First list regular GBA files
for /r "%GBA_DIR%" %%f in (*.gba) do (
    :: Skip if filename suggests it's not a ROM
    set "SKIP_FILE=false"
    
    :: Skip if it contains these strings
    echo "%%~nf" | findstr /i "update patch save" >nul
    if not errorlevel 1 set "SKIP_FILE=true"
    
    if "!SKIP_FILE!"=="false" (
        set /a "ROM_NUM+=1"
        set "ROM_PATH[!ROM_NUM!]=%%~dpnxf"
        set "ROM_NAME[!ROM_NUM!]=%%~nf"
        set "ROM_FILE[!ROM_NUM!]=%%~nxf"
        set "ROM_DIR[!ROM_NUM!]=%%~dpf"
        set "ROM_TYPE[!ROM_NUM!]=GBA"
        
        :: Display name with subfolder if not in main GBA folder
        set "DISPLAY_NAME=%%~nf"
        set "REL_PATH=%%~dpf"
        set "REL_PATH=!REL_PATH:%GBA_DIR%\=!"
        if not "!REL_PATH!"=="!GBA_DIR!" (
            if not "!REL_PATH!"=="" (
                set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf"
            )
        )
        
        :: Check if save exists and add indicator
        set "SAVE_EXISTS="
        if exist "%SAVE_DIR%\gba\!ROM_NAME[%ROM_NUM%]!.sav" set "SAVE_EXISTS=[SAVE]"
        
        :: Check playtime and add indicator
        set "PLAYTIME="
        if exist "%PLAYTIME_FILE%" (
            for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%" ^| findstr /i "^!ROM_NAME[%ROM_NUM%]!="') do (
                set /a "HOURS=%%b/60"
                set /a "MINS=%%b%%60"
                if !HOURS! gtr 0 (
                    set "PLAYTIME=[!HOURS!h !MINS!m]"
                ) else (
                    set "PLAYTIME=[!MINS!m]"
                )
            )
        )
        
        echo !ROM_NUM!. !DISPLAY_NAME! !SAVE_EXISTS! !PLAYTIME!
    )
)

:: Then list ZIP files potentially containing GBA ROMs
for /r "%GBA_DIR%" %%f in (*.zip) do (
    set "SKIP_FILE=false"
    
    :: Skip ZIPs with non-game-like names
    echo "%%~nf" | findstr /i "update patch save" >nul
    if not errorlevel 1 set "SKIP_FILE=true"
    
    if "!SKIP_FILE!"=="false" (
        set /a "ROM_NUM+=1"
        set "ROM_PATH[!ROM_NUM!]=%%~dpnxf"
        set "ROM_NAME[!ROM_NUM!]=%%~nf"
        set "ROM_FILE[!ROM_NUM!]=%%~nxf"
        set "ROM_DIR[!ROM_NUM!]=%%~dpf"
        set "ROM_TYPE[!ROM_NUM!]=ZIP"
        
        :: Display name with subfolder if not in main GBA folder
        set "DISPLAY_NAME=%%~nf [ZIP]"
        set "REL_PATH=%%~dpf"
        set "REL_PATH=!REL_PATH:%GBA_DIR%\=!"
        if not "!REL_PATH!"=="!GBA_DIR!" (
            if not "!REL_PATH!"=="" (
                set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf [ZIP]"
            )
        )
        
        :: Check if save exists and add indicator
        set "SAVE_EXISTS="
        if exist "%SAVE_DIR%\gba\!ROM_NAME[%ROM_NUM%]!.sav" set "SAVE_EXISTS=[SAVE]"
        
        :: Check playtime and add indicator
        set "PLAYTIME="
        if exist "%PLAYTIME_FILE%" (
            for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%" ^| findstr /i "^!ROM_NAME[%ROM_NUM%]!="') do (
                set /a "HOURS=%%b/60"
                set /a "MINS=%%b%%60"
                if !HOURS! gtr 0 (
                    set "PLAYTIME=[!HOURS!h !MINS!m]"
                ) else (
                    set "PLAYTIME=[!MINS!m]"
                )
            )
        )
        
        echo !ROM_NUM!. !DISPLAY_NAME! !SAVE_EXISTS! !PLAYTIME!
    )
)

if %ROM_NUM% equ 0 (
    echo No GBA ROMs found in the gba folder.
    echo Please add some GBA ROMs to: %GBA_DIR%
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

echo.
echo 0. Return to main menu
echo F. Mark ROM as favorite
echo.

set /p rom_choice="Enter ROM number to play: "

if "%rom_choice%"=="0" goto MainMenu
if /i "%rom_choice%"=="F" goto MarkGBAFavorite

:: Validate input
set /a rom_num=%rom_choice% 2>nul
if %rom_num% lss 1 goto GBAGames
if %rom_num% gtr %ROM_NUM% goto GBAGames

:: Start tracking playtime
call :StartTimeTracking

:: Launch the selected GBA ROM
cls
echo ========================================================
echo                 LAUNCHING GBA GAME
echo ========================================================
echo.
echo Launching: !ROM_NAME[%rom_num%]!
echo Path: !ROM_PATH[%rom_num%]!
echo Using emulator: %GBA_EMU_PATH%
echo.

:: Start JoyToKey if it exists and has a profile
if "%JOYTOKEY_FOUND%"=="true" (
    if exist "%TOOLS_DIR%\JoyToKey\Profiles\!ROM_NAME[%rom_num%]!.cfg" (
        echo Starting JoyToKey with game-specific profile...
        start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\!ROM_NAME[%rom_num%]!.cfg"
    ) else if exist "%TOOLS_DIR%\JoyToKey\Profiles\GBA.cfg" (
        echo Starting JoyToKey with default GBA profile...
        start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\GBA.cfg"
    ) else (
        echo Starting JoyToKey with default profile...
        start "" "%JOYTOKEY_PATH%"
    )
)

:: Check if it's a ZIP file
if "!ROM_TYPE[%rom_num%]!"=="ZIP" (
    :: For ZIP files, we have two options:
    :: 1. Extract and run the GBA file (works with all emulators)
    :: 2. Pass the ZIP directly (works with some emulators like mGBA)
    
    :: Check if we should try direct ZIP loading based on emulator
    set "DIRECT_ZIP=false"
    if /i "%GBA_EMU_NAME%"=="mGBA" set "DIRECT_ZIP=true"
    
    if "!DIRECT_ZIP!"=="true" (
        echo This emulator supports direct ZIP loading. Launching from ZIP...
        
        :: Create save directory if it doesn't exist
        if not exist "%SAVE_DIR%\gba" mkdir "%SAVE_DIR%\gba"
        
        :: Determine emulator-specific save options
        set "SAVE_ARGS="
        
        if /i "%GBA_EMU_NAME%"=="mGBA" (
            set "SAVE_ARGS=-s "%SAVE_DIR%\gba\!ROM_NAME[%rom_num%]!.sav""
        )
        
        echo.
        echo Save files will be stored in:
        echo %SAVE_DIR%\gba\
        echo.
        echo When you're done playing, close the emulator window.
        echo.
        timeout /t 3 >nul
        
        :: Launch the emulator with the ZIP file directly
        call :SafeLaunch start "" "%GBA_EMU_PATH%" !SAVE_ARGS! "!ROM_PATH[%rom_num%]!"
        
    ) else (
        echo Extracting ROM from ZIP archive...
        
        :: Create temporary directory for extraction
        set "EXTRACT_DIR=%TEMP_DIR%\!ROM_NAME[%rom_num%]!"
        if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!"
        mkdir "!EXTRACT_DIR!"
        
        :: Create a safe path version without special characters
        set "SAFE_PATH=!ROM_PATH[%rom_num%]!"
        set "SAFE_PATH=!SAFE_PATH:&=^&!"
        set "SAFE_PATH=!SAFE_PATH:(=^(!"
        set "SAFE_PATH=!SAFE_PATH:)=^)!"
        set "SAFE_PATH=!SAFE_PATH:>=^>!"
        set "SAFE_PATH=!SAFE_PATH:<=^<!"
        set "SAFE_PATH=!SAFE_PATH:|=^|!"
        
        :: Extract ZIP file with error handling
        echo Using PowerShell to extract files...
        powershell -command "try { Expand-Archive -LiteralPath '!SAFE_PATH!' -DestinationPath '!EXTRACT_DIR!' -Force } catch { exit 1 }" >nul 2>&1
        if errorlevel 1 (
            echo PowerShell extraction failed, trying alternate methods...
            
            :: Try 7-Zip if available
            if exist "%EMULATORS_DIR%\7z.exe" (
                "%EMULATORS_DIR%\7z.exe" x -y "!ROM_PATH[%rom_num%]!" -o"!EXTRACT_DIR!" >nul
            ) else if exist "%UNZIP_PATH%" (
                "%UNZIP_PATH%" x -y "!ROM_PATH[%rom_num%]!" -o"!EXTRACT_DIR!" >nul
            ) else {
                echo Unable to extract ZIP file: format not supported
                echo Please install 7-Zip in the emulators folder for better ZIP support
                goto ErrorHandler
            }
        )
        
        echo Extraction complete. Searching for GBA ROMs...
        echo.
        
        :: Debug output - list the contents of extracted directory
        echo Files found in extraction directory:
        dir /b "!EXTRACT_DIR!" | findstr /i "\.gba$"
        echo.
        
        :: Find GBA ROM in the extracted directory
        set "FOUND_ROM=false"
        set "EXTRACT_ROM="
        
        :: First try ROM with same name as ZIP
        if exist "!EXTRACT_DIR!\!ROM_NAME[%rom_num%]!.gba" (
            set "FOUND_ROM=true"
            set "EXTRACT_ROM=!EXTRACT_DIR!\!ROM_NAME[%rom_num%]!.gba"
            echo Found matching GBA ROM: !ROM_NAME[%rom_num%]!.gba
        )
        
        :: If not found, search all subdirectories
        if "!FOUND_ROM!"=="false" (
            for /r "!EXTRACT_DIR!" %%g in (*.gba) do (
                if "!FOUND_ROM!"=="false" (
                    set "FOUND_ROM=true"
                    set "EXTRACT_ROM=%%~dpnxg"
                    echo Found GBA ROM: %%~nxg
                )
            )
        )
        
        if "!FOUND_ROM!"=="false" (
            echo No GBA ROM found in the ZIP archive.
            echo Contents of extracted folder:
            dir /s /b "!EXTRACT_DIR!"
            echo.
            echo Press any key to return to the ROM list...
            pause >nul
            goto GBAGames
        )
        
        :: Create save directory if it doesn't exist
        if not exist "%SAVE_DIR%\gba" mkdir "%SAVE_DIR%\gba"
        
        :: Determine emulator-specific save options
        set "SAVE_ARGS="
        
        if /i "%GBA_EMU_NAME%"=="VisualBoyAdvance" (
            set "SAVE_ARGS=--battery-dir "%SAVE_DIR%\gba""
        ) else if /i "%GBA_EMU_NAME%"=="mGBA" (
            set "SAVE_ARGS=-s "%SAVE_DIR%\gba\!ROM_NAME[%rom_num%]!.sav""
        ) else if /i "%GBA_EMU_NAME%"=="VBA" (
            set "SAVE_ARGS=--battery-dir "%SAVE_DIR%\gba""
        )
        
        echo.
        echo Save files will be stored in:
        echo %SAVE_DIR%\gba\
        echo.
        echo When you're done playing, close the emulator window.
        echo.
        timeout /t 3 >nul
        
        :: Launch the emulator with the extracted ROM
        call :SafeLaunch start "" "%GBA_EMU_PATH%" !SAVE_ARGS! "!EXTRACT_ROM!"
    )
    
) else (
    :: Regular GBA file
    :: Create save directory if it doesn't exist
    if not exist "%SAVE_DIR%\gba" mkdir "%SAVE_DIR%\gba"
    
    :: Determine emulator-specific save options
    set "SAVE_ARGS="
    
    if /i "%GBA_EMU_NAME%"=="VisualBoyAdvance" (
        set "SAVE_ARGS=--battery-dir "%SAVE_DIR%\gba""
    ) else if /i "%GBA_EMU_NAME%"=="mGBA" (
        set "SAVE_ARGS=-s "%SAVE_DIR%\gba\!ROM_NAME[%rom_num%]!.sav""
    ) else if /i "%GBA_EMU_NAME%"=="VBA" (
        set "SAVE_ARGS=--battery-dir "%SAVE_DIR%\gba""
    )
    
    echo Save files will be stored in:
    echo %SAVE_DIR%\gba\
    echo.
    echo When you're done playing, close the emulator window.
    echo.
    timeout /t 3 >nul
    
    :: Start the emulator with the full path and save args
    call :SafeLaunch start "" "%GBA_EMU_PATH%" !SAVE_ARGS! "!ROM_PATH[%rom_num%]!"
)

:: Wait for emulator to close
echo Game launched! Press any key AFTER closing the emulator to return to the menu...
pause >nul

:: End tracking and update playtime
call :EndTimeTracking

goto MainMenu
:: =================== MARK GBA FAVORITE ===================
:MarkGBAFavorite
cls
echo ========================================================
echo                MARK FAVORITE GBA GAME
echo ========================================================
echo.

echo Select a ROM to mark as favorite:
echo.

for /l %%i in (1,1,%ROM_NUM%) do (
    :: Display name with subfolder if not in main GBA folder
    set "DISPLAY_NAME=!ROM_NAME[%%i]!"
    set "REL_PATH=!ROM_DIR[%%i]!"
    set "REL_PATH=!REL_PATH:%GBA_DIR%\=!"
    if not "!REL_PATH!"=="!GBA_DIR!" (
        if not "!REL_PATH!"=="" (
            set "DISPLAY_NAME=[!REL_PATH:~0,-1!] !ROM_NAME[%%i]!"
        )
    )
    
    :: Add [ZIP] indicator for ZIP files
    if "!ROM_TYPE[%%i]!"=="ZIP" (
        set "DISPLAY_NAME=!DISPLAY_NAME! [ZIP]"
    )
    
    echo %%i. !DISPLAY_NAME!
)

echo.
echo 0. Return to ROMs list
echo.

set /p fav_choice="Enter ROM number: "

if "%fav_choice%"=="0" goto GBAGames

:: Validate input
set /a fav_num=%fav_choice% 2>nul
if %fav_num% lss 1 goto MarkGBAFavorite
if %fav_num% gtr %ROM_NUM% goto MarkGBAFavorite

:: Add to favorites
if not exist "%FAV_DIR%\favorites.txt" (
    echo ; FAVORITES > "%FAV_DIR%\favorites.txt"
)

:: Create a link to the ROM in the favorites file
echo GBA:!ROM_NAME[%fav_num%]!=!ROM_PATH[%fav_num%]!>> "%FAV_DIR%\favorites.txt"

echo.
echo GBA ROM marked as favorite!
timeout /t 2 >nul
goto GBAGames

:: =================== GAME STATISTICS ===================
:GameStats
cls
echo ========================================================
echo                    GAME STATISTICS
echo ========================================================
echo.

if not exist "%RECENT_FILE%" (
    echo No recently played games found.
    echo.
    goto ShowPlaytime
)

echo RECENTLY PLAYED GAMES:
echo ---------------------
set "COUNT=0"
for /f "tokens=1,* delims==" %%a in ('type "%RECENT_FILE%"') do (
    set /a "COUNT+=1"
    if !COUNT! leq 10 echo %%a (%%b)
)
echo.

:ShowPlaytime
if not exist "%PLAYTIME_FILE%" (
    echo No playtime data available.
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

echo MOST PLAYED GAMES:
echo ----------------
:: Sort playtime file by time (descending)
set "SORT_FILE=%TEMP%\playtime_sorted.txt"
type "%PLAYTIME_FILE%" | sort /R > "%SORT_FILE%" 2>nul

set "COUNT=0"
for /f "tokens=1,* delims==" %%a in ('type "%SORT_FILE%"') do (
    if !COUNT! lss 10 (
        set /a "HOURS=%%b/60"
        set /a "MINS=%%b%%60"
        if !HOURS! gtr 0 (
            echo %%a: !HOURS! hours !MINS! minutes
        ) else (
            echo %%a: !MINS! minutes
        )
        set /a "COUNT+=1"
    )
)
echo.
echo Total tracked games: %COUNT%
echo.
echo Press any key to return to the main menu...
pause >nul
goto MainMenu

:: =================== BACKUP MANAGER ===================
:BackupManager
cls
echo ========================================================
echo                    BACKUP MANAGER
echo ========================================================
echo.
echo 1. Backup Save Files
echo 2. Restore from Backup
echo 3. Schedule Automatic Backups
echo 4. Auto-Backup Settings
echo 0. Return to Main Menu
echo.

set /p backup_choice="Enter your choice: "

if "%backup_choice%"=="0" goto MainMenu
if "%backup_choice%"=="1" goto CreateBackup
if "%backup_choice%"=="2" goto RestoreBackup
if "%backup_choice%"=="3" goto ScheduleBackup
if "%backup_choice%"=="4" goto AutoBackupSettings

echo Invalid choice. Press any key to continue...
pause >nul
goto BackupManager

:CreateBackup
echo.
echo Creating backup of save files...

:: Create backup directory if it doesn't exist
set "BACKUP_DIR=%ROOT_DIR%backups"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Create timestamp for backup folder
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set "DATE=%%c-%%a-%%b")
for /f "tokens=1-2 delims=: " %%a in ('time /t') do (set "TIME=%%a%%b")
set "BACKUP_NAME=backup_%DATE%_%TIME%"
set "BACKUP_PATH=%BACKUP_DIR%\%BACKUP_NAME%"
mkdir "%BACKUP_PATH%"

:: Backup DOS saves
if exist "%SAVE_DIR%\dos" (
    mkdir "%BACKUP_PATH%\dos"
    xcopy /s /i /y "%SAVE_DIR%\dos" "%BACKUP_PATH%\dos" >nul
)

:: Backup GBA saves
if exist "%SAVE_DIR%\gba" (
    mkdir "%BACKUP_PATH%\gba"
    xcopy /s /i /y "%SAVE_DIR%\gba" "%BACKUP_PATH%\gba" >nul
)

:: Backup configuration and statistics
if exist "%ROOT_DIR%\*.dat" xcopy /y "%ROOT_DIR%\*.dat" "%BACKUP_PATH%\" >nul
if exist "%ROOT_DIR%\*.txt" xcopy /y "%ROOT_DIR%\*.txt" "%BACKUP_PATH%\" >nul
if exist "%EMULATORS_DIR%\*.conf" xcopy /y "%EMULATORS_DIR%\*.conf" "%BACKUP_PATH%\" >nul

echo Backup created successfully in:
echo %BACKUP_PATH%
echo.

:: Keep only the 10 most recent backups (increased from 5)
set "BACKUP_COUNT=0"
for /d %%d in ("%BACKUP_DIR%\backup_*") do set /a "BACKUP_COUNT+=1"

if %BACKUP_COUNT% gtr 10 (
    echo Removing old backups (keeping only the 10 most recent)...
    set "OLDEST_BACKUP="
    for /f "tokens=*" %%d in ('dir /b /od /ad "%BACKUP_DIR%\backup_*"') do (
        if %BACKUP_COUNT% gtr 10 (
            set "OLDEST_BACKUP=%%d"
            rmdir /s /q "%BACKUP_DIR%\!OLDEST_BACKUP!"
            set /a "BACKUP_COUNT-=1"
        )
    )
)

:: Log the backup in backup_history.log
echo %DATE% %TIME% - Backup created: %BACKUP_NAME% >> "%BACKUP_DIR%\backup_history.log"

echo Press any key to return to Backup Manager...
pause >nul
goto BackupManager

:RestoreBackup
cls
echo ========================================================
echo                  RESTORE FROM BACKUP
echo ========================================================
echo.

set "BACKUP_DIR=%ROOT_DIR%backups"
if not exist "%BACKUP_DIR%" (
    echo No backups found.
    echo.
    echo Press any key to return to Backup Manager...
    pause >nul
    goto BackupManager
)

echo Available backups:
echo.

set "BACKUP_NUM=0"
for /d %%d in ("%BACKUP_DIR%\backup_*") do (
    set /a "BACKUP_NUM+=1"
    set "BACKUP_PATH[!BACKUP_NUM!]=%%d"
    set "BACKUP_NAME[!BACKUP_NUM!]=%%~nxd"
    
    :: Try to get creation date
    for /f "tokens=1,2" %%x in ('dir /tc "%%d" ^| findstr /i "%%~nxd"') do set "BACKUP_DATE[!BACKUP_NUM!]=%%x %%y"
    
    echo !BACKUP_NUM!. !BACKUP_NAME[%BACKUP_NUM%]! (!BACKUP_DATE[%BACKUP_NUM%]!)
)

if %BACKUP_NUM% equ 0 (
    echo No backups found.
    echo.
    echo Press any key to return to Backup Manager...
    pause >nul
    goto BackupManager
)

echo.
echo 0. Return to Backup Manager
echo.

set /p restore_choice="Enter backup number to restore: "

if "%restore_choice%"=="0" goto BackupManager

:: Validate input
set /a backup_num=%restore_choice% 2>nul
if %backup_num% lss 1 goto RestoreBackup
if %backup_num% gtr %BACKUP_NUM% goto RestoreBackup

echo.
echo Are you sure you want to restore from !BACKUP_NAME[%backup_num%]!?
echo This will overwrite your current save files.
echo.
set /p confirm="Type YES to confirm: "

if /i not "%confirm%"=="YES" (
    echo.
    echo Restore cancelled.
    timeout /t 2 >nul
    goto RestoreBackup
)

echo.
echo Restoring save files from backup...

:: Create a backup of current state before restoring (safety measure)
echo Creating safety backup of current state before restore...
set "SAFETY_BACKUP=pre_restore_%DATE%_%TIME%"
set "SAFETY_PATH=%BACKUP_DIR%\%SAFETY_BACKUP%"
mkdir "%SAFETY_PATH%"

:: Quick backup of current state
if exist "%SAVE_DIR%\dos" xcopy /s /i /y "%SAVE_DIR%\dos" "%SAFETY_PATH%\dos" >nul
if exist "%SAVE_DIR%\gba" xcopy /s /i /y "%SAVE_DIR%\gba" "%SAFETY_PATH%\gba" >nul
if exist "%ROOT_DIR%\*.dat" xcopy /y "%ROOT_DIR%\*.dat" "%SAFETY_PATH%\" >nul
if exist "%ROOT_DIR%\*.txt" xcopy /y "%ROOT_DIR%\*.txt" "%SAFETY_PATH%\" >nul

:: Restore DOS saves
if exist "!BACKUP_PATH[%backup_num%]!\dos" (
    if exist "%SAVE_DIR%\dos" rd /s /q "%SAVE_DIR%\dos"
    mkdir "%SAVE_DIR%\dos"
    xcopy /s /i /y "!BACKUP_PATH[%backup_num%]!\dos" "%SAVE_DIR%\dos" >nul
)

:: Restore GBA saves
if exist "!BACKUP_PATH[%backup_num%]!\gba" (
    if exist "%SAVE_DIR%\gba" rd /s /q "%SAVE_DIR%\gba"
    mkdir "%SAVE_DIR%\gba"
    xcopy /s /i /y "!BACKUP_PATH[%backup_num%]!\gba" "%SAVE_DIR%\gba" >nul
)

:: Restore configuration (optional)
echo.
echo Do you want to restore configuration and statistics as well?
set /p config_restore="Type YES to restore configuration: "

if /i "%config_restore%"=="YES" (
    if exist "!BACKUP_PATH[%backup_num%]!\*.dat" xcopy /y "!BACKUP_PATH[%backup_num%]!\*.dat" "%ROOT_DIR%\" >nul
    if exist "!BACKUP_PATH[%backup_num%]!\*.txt" xcopy /y "!BACKUP_PATH[%backup_num%]!\*.txt" "%ROOT_DIR%\" >nul
    if exist "!BACKUP_PATH[%backup_num%]!\*.conf" xcopy /y "!BACKUP_PATH[%backup_num%]!\*.conf" "%EMULATORS_DIR%\" >nul
)

echo.
echo Restore completed successfully!
echo A safety backup of your previous state was created as: %SAFETY_BACKUP%
echo.

:: Log the restore in backup_history.log
echo %DATE% %TIME% - Restore from: !BACKUP_NAME[%backup_num%]! >> "%BACKUP_DIR%\backup_history.log"

echo Press any key to return to Backup Manager...
pause >nul
goto BackupManager
:ScheduleBackup
cls
echo ========================================================
echo                SCHEDULED BACKUPS
echo ========================================================
echo.
echo This feature will create a batch file that you can add to
echo Windows Task Scheduler to perform automatic backups.
echo.
echo 1. Daily Backup
echo 2. Weekly Backup
echo 3. Monthly Backup
echo 4. Manual (On Demand) Backup Script
echo 0. Return to Backup Manager
echo.

set /p schedule_choice="Enter your choice: "

if "%schedule_choice%"=="0" goto BackupManager
if "%schedule_choice%"=="1" set "SCHEDULE_TYPE=Daily"
if "%schedule_choice%"=="2" set "SCHEDULE_TYPE=Weekly"
if "%schedule_choice%"=="3" set "SCHEDULE_TYPE=Monthly"
if "%schedule_choice%"=="4" set "SCHEDULE_TYPE=Manual"

if "%SCHEDULE_TYPE%"=="" (
    echo Invalid choice. Press any key to continue...
    pause >nul
    goto ScheduleBackup
)

set "BACKUP_SCRIPT=%ROOT_DIR%backup_%SCHEDULE_TYPE%.bat"

:: Create the backup script
> "%BACKUP_SCRIPT%" (
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo.
    echo :: Backup script created by Ultimate Kids Game Launcher
    echo :: Schedule type: %SCHEDULE_TYPE%
    echo :: Created on: %DATE% %TIME%
    echo.
    echo :: Create backup directory if it doesn't exist
    echo set "ROOT_DIR=%ROOT_DIR%"
    echo set "SAVE_DIR=%SAVE_DIR%"
    echo set "BACKUP_DIR=%%ROOT_DIR%%backups"
    echo if not exist "%%BACKUP_DIR%%" mkdir "%%BACKUP_DIR%%"
    echo.
    echo :: Create timestamp for backup folder
    echo for /f "tokens=2-4 delims=/ " %%%%a in ('date /t') do (set "DATE=%%%%c-%%%%a-%%%%b")
    echo for /f "tokens=1-2 delims=: " %%%%a in ('time /t') do (set "TIME=%%%%a%%%%b")
    echo set "BACKUP_NAME=backup_%%DATE%%_%%TIME%%_%SCHEDULE_TYPE%"
    echo set "BACKUP_PATH=%%BACKUP_DIR%%\%%BACKUP_NAME%%"
    echo mkdir "%%BACKUP_PATH%%"
    echo.
    echo :: Backup DOS saves
    echo if exist "%%SAVE_DIR%%\dos" (
    echo     mkdir "%%BACKUP_PATH%%\dos"
    echo     xcopy /s /i /y "%%SAVE_DIR%%\dos" "%%BACKUP_PATH%%\dos" ^>nul
    echo     echo Backed up DOS saves
    echo )
    echo.
    echo :: Backup GBA saves
    echo if exist "%%SAVE_DIR%%\gba" (
    echo     mkdir "%%BACKUP_PATH%%\gba"
    echo     xcopy /s /i /y "%%SAVE_DIR%%\gba" "%%BACKUP_PATH%%\gba" ^>nul
    echo     echo Backed up GBA saves
    echo )
    echo.
    echo :: Backup configuration and statistics
    echo if exist "%%ROOT_DIR%%\*.dat" xcopy /y "%%ROOT_DIR%%\*.dat" "%%BACKUP_PATH%%\" ^>nul
    echo if exist "%%ROOT_DIR%%\*.txt" xcopy /y "%%ROOT_DIR%%\*.txt" "%%BACKUP_PATH%%\" ^>nul
    echo if exist "%%ROOT_DIR%%\emulators\*.conf" xcopy /y "%%ROOT_DIR%%\emulators\*.conf" "%%BACKUP_PATH%%\" ^>nul
    echo echo Backed up configuration files
    echo.
    echo :: Keep only the 15 most recent backups
    echo set "BACKUP_COUNT=0"
    echo for /d %%%%d in ("%%BACKUP_DIR%%\backup_*") do set /a "BACKUP_COUNT+=1"
    echo.
    echo if %%BACKUP_COUNT%% gtr 15 (
    echo     echo Cleaning up old backups [keeping 15 most recent]
    echo     set "OLDEST_BACKUP="
    echo     for /f "tokens=*" %%%%d in ('dir /b /od /ad "%%BACKUP_DIR%%\backup_*"') do (
    echo         if %%BACKUP_COUNT%% gtr 15 (
    echo             set "OLDEST_BACKUP=%%%%d"
    echo             rmdir /s /q "%%BACKUP_DIR%%\!OLDEST_BACKUP!"
    echo             set /a "BACKUP_COUNT-=1"
    echo             echo Removed old backup: !OLDEST_BACKUP!
    echo         )
    echo     )
    echo )
    echo.
    echo :: Log the backup
    echo echo %%DATE%% %%TIME%% - %SCHEDULE_TYPE% Backup created: %%BACKUP_NAME%% ^>^> "%%BACKUP_DIR%%\backup_history.log"
    echo.
    echo echo Backup completed: %%BACKUP_PATH%%
)

echo Backup script created at:
echo %BACKUP_SCRIPT%
echo.
echo To schedule this backup:
echo 1. Open Windows Task Scheduler (taskschd.msc)
echo 2. Create a new task
echo 3. Add an action to Start a Program
echo 4. Browse to this script: %BACKUP_SCRIPT%
echo 5. Set the trigger according to your needs:
if "%SCHEDULE_TYPE%"=="Daily" echo    - Daily at a time of your choice
if "%SCHEDULE_TYPE%"=="Weekly" echo    - Weekly on a day of your choice
if "%SCHEDULE_TYPE%"=="Monthly" echo    - Monthly on a date of your choice
echo.
echo Press any key to return to Backup Manager...
pause >nul
goto BackupManager

:AutoBackupSettings
cls
echo ========================================================
echo                AUTO-BACKUP SETTINGS
echo ========================================================
echo.
echo This feature will enable backups to be created automatically
echo when you exit the launcher.
echo.

:: Check if auto-backup is enabled
set "AUTO_BACKUP=false"
set "AUTO_BACKUP_CONFIG=%ROOT_DIR%auto_backup.cfg"

if exist "%AUTO_BACKUP_CONFIG%" (
    for /f "tokens=1,* delims==" %%a in ('type "%AUTO_BACKUP_CONFIG%"') do (
        if "%%a"=="AutoBackup" set "AUTO_BACKUP=%%b"
    )
)

if "%AUTO_BACKUP%"=="true" (
    echo Auto-backup is currently ENABLED
    echo.
    echo 1. Disable auto-backup
) else (
    echo Auto-backup is currently DISABLED
    echo.
    echo 1. Enable auto-backup
)
echo 0. Return to Backup Manager
echo.

set /p auto_choice="Enter your choice: "

if "%auto_choice%"=="0" goto BackupManager
if "%auto_choice%"=="1" (
    if "%AUTO_BACKUP%"=="true" (
        > "%AUTO_BACKUP_CONFIG%" echo AutoBackup=false
        echo Auto-backup has been disabled.
    ) else (
        > "%AUTO_BACKUP_CONFIG%" echo AutoBackup=true
        echo Auto-backup has been enabled.
        echo Backups will be created when you exit the launcher.
    )
    timeout /t 2 >nul
)
goto BackupManager

:: =================== CONTROLLER SETUP ===================
:ControllerSetup
cls
echo ========================================================
echo                  CONTROLLER SETUP
echo ========================================================
echo.

if not "%JOYTOKEY_FOUND%"=="true" (
    echo JoyToKey not found in tools folder!
    echo.
    echo To use controllers, you need JoyToKey.exe in:
    echo %TOOLS_DIR%\JoyToKey\
    echo.
    echo You can download JoyToKey from:
    echo https://joytokey.net/en/download
    echo.
    echo After downloading, extract it to the tools\JoyToKey folder.
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

echo 1. Configure Controller for DOS Games
echo 2. Configure Controller for GBA Games
echo 3. Configure Controller for Specific Game
echo 4. Launch JoyToKey Config Tool
echo 0. Return to Main Menu
echo.

set /p controller_choice="Enter your choice: "

if "%controller_choice%"=="0" goto MainMenu
if "%controller_choice%"=="1" goto ConfigureDOSController
if "%controller_choice%"=="2" goto ConfigureGBAController
if "%controller_choice%"=="3" goto ConfigureGameController
if "%controller_choice%"=="4" (
    start "" "%JOYTOKEY_PATH%"
    goto ControllerSetup
)

echo Invalid choice. Press any key to continue...
pause >nul
goto ControllerSetup

:ConfigureDOSController
cls
echo ========================================================
echo              CONFIGURE DOS GAME CONTROLLER
echo ========================================================
echo.
echo This will launch JoyToKey and save a configuration for DOSBox.
echo.
echo Instructions:
echo 1. When JoyToKey opens, connect your controller
echo 2. Configure the buttons for DOSBox controls
echo 3. Go to [File] menu and select [Save Configuration]
echo 4. Save the file as "DOSBox.cfg" in the JoyToKey Profiles folder
echo.
echo Recommended mappings:
echo - D-pad/Left stick: Arrow keys
echo - A button: Enter
echo - B button: Escape
echo - X button: Space
echo - Y button: Alt
echo - L/R buttons: Ctrl/Shift
echo.
echo Press any key to launch JoyToKey...
pause >nul

if not exist "%TOOLS_DIR%\JoyToKey\Profiles" mkdir "%TOOLS_DIR%\JoyToKey\Profiles"
start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg"

echo.
echo JoyToKey has been launched.
echo After saving your configuration, press any key to return...
pause >nul
goto ControllerSetup

:ConfigureGBAController
cls
echo ========================================================
echo              CONFIGURE GBA GAME CONTROLLER
echo ========================================================
echo.
echo This will launch JoyToKey and save a configuration for GBA games.
echo.
echo Instructions:
echo 1. When JoyToKey opens, connect your controller
echo 2. Configure the buttons for GBA emulator controls
echo 3. Go to [File] menu and select [Save Configuration]
echo 4. Save the file as "GBA.cfg" in the JoyToKey Profiles folder
echo.
echo Recommended mappings:
echo - D-pad: Arrow keys
echo - A button: Z key (usually A button in emulators)
echo - B button: X key (usually B button in emulators)
echo - L button: A key
echo - R button: S key
echo - Start: Enter
echo - Select: Backspace
echo.
echo Press any key to launch JoyToKey...
pause >nul

if not exist "%TOOLS_DIR%\JoyToKey\Profiles" mkdir "%TOOLS_DIR%\JoyToKey\Profiles"
start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\GBA.cfg"

echo.
echo JoyToKey has been launched.
echo After saving your configuration, press any key to return...
pause >nul
goto ControllerSetup

:ConfigureGameController
cls
echo ========================================================
echo            CONFIGURE GAME-SPECIFIC CONTROLLER
echo ========================================================
echo.
echo This will create a controller profile for a specific game.
echo.
echo Choose the game type:
echo 1. DOS Game
echo 2. GBA Game
echo 3. CD-ROM Game
echo 0. Back to Controller Setup
echo.

set /p game_type_choice="Enter your choice: "

if "%game_type_choice%"=="0" goto ControllerSetup
if "%game_type_choice%"=="1" set "GAME_TYPE=DOS" & goto SelectSpecificGame
if "%game_type_choice%"=="2" set "GAME_TYPE=GBA" & goto SelectSpecificGame
if "%game_type_choice%"=="3" set "GAME_TYPE=ISO" & goto SelectSpecificGame

echo Invalid choice. Press any key to continue...
pause >nul
goto ConfigureGameController

:SelectSpecificGame
cls
echo ========================================================
echo              SELECT GAME FOR CONTROLLER PROFILE
echo ========================================================
echo.
echo Choose a game to create a controller profile for:
echo.

set "GAME_NUM=0"
set "GAME_LIST="

if "%GAME_TYPE%"=="DOS" (
    :: List DOS games
    for /r "%GAMES_DIR%" %%f in (*.exe *.com *.bat) do (
        :: Skip common non-game files
        set "SKIP_FILE=false"
        
        :: Exclude common non-game executables by name
        for %%n in (install setup config unins remove update setup_wizard readme help register) do (
            if /i "%%~nf"=="%%n" set "SKIP_FILE=true"
        )
        
        :: Also check if name contains these strings
        echo "%%~nf" | findstr /i "install setup config unins remove update setup_ readme help register _setup" >nul
        if not errorlevel 1 set "SKIP_FILE=true"
        
        if "!SKIP_FILE!"=="false" (
            set /a "GAME_NUM+=1"
            set "GAME_PATH[!GAME_NUM!]=%%~dpnxf"
            set "GAME_NAME[!GAME_NUM!]=%%~nf"
            
            :: Display name with subfolder if not in main games folder
            set "DISPLAY_NAME=%%~nf"
            set "REL_PATH=%%~dpf"
            set "REL_PATH=!REL_PATH:%GAMES_DIR%\=!"
            if not "!REL_PATH!"=="!GAMES_DIR!" (
                if not "!REL_PATH!"=="" (
                    set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf"
                )
            )
            
            echo !GAME_NUM!. !DISPLAY_NAME!
        )
    )
    
    :: Then list ZIP files potentially containing DOS games
    for /r "%GAMES_DIR%" %%f in (*.zip) do (
        set "SKIP_FILE=false"
        
        :: Skip ZIPs with non-game-like names
        echo "%%~nf" | findstr /i "update patch save install setup" >nul
        if not errorlevel 1 set "SKIP_FILE=true"
        
        if "!SKIP_FILE!"=="false" (
            set /a "GAME_NUM+=1"
            set "GAME_PATH[!GAME_NUM!]=%%~dpnxf"
            set "GAME_NAME[!GAME_NUM!]=%%~nf"
            
            :: Display name with subfolder if not in main games folder
            set "DISPLAY_NAME=%%~nf [ZIP]"
            set "REL_PATH=%%~dpf"
            set "REL_PATH=!REL_PATH:%GAMES_DIR%\=!"
            if not "!REL_PATH!"=="!GAMES_DIR!" (
                if not "!REL_PATH!"=="" (
                    set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf [ZIP]"
                )
            )
            
            echo !GAME_NUM!. !DISPLAY_NAME!
        )
    )
) else if "%GAME_TYPE%"=="GBA" (
    :: List GBA ROMs
    for /r "%GBA_DIR%" %%f in (*.gba) do (
        :: Skip if filename suggests it's not a ROM
        set "SKIP_FILE=false"
        
        :: Skip if it contains these strings
        echo "%%~nf" | findstr /i "update patch save" >nul
        if not errorlevel 1 set "SKIP_FILE=true"
        
        if "!SKIP_FILE!"=="false" (
            set /a "GAME_NUM+=1"
            set "GAME_PATH[!GAME_NUM!]=%%~dpnxf"
            set "GAME_NAME[!GAME_NUM!]=%%~nf"
            
            :: Display name with subfolder if not in main GBA folder
            set "DISPLAY_NAME=%%~nf"
            set "REL_PATH=%%~dpf"
            set "REL_PATH=!REL_PATH:%GBA_DIR%\=!"
            if not "!REL_PATH!"=="!GBA_DIR!" (
                if not "!REL_PATH!"=="" (
                    set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf"
                )
            )
            
            echo !GAME_NUM!. !DISPLAY_NAME!
        )
    )
    
    :: Then list ZIP files potentially containing GBA ROMs
    for /r "%GBA_DIR%" %%f in (*.zip) do (
        set "SKIP_FILE=false"
        
        :: Skip ZIPs with non-game-like names
        echo "%%~nf" | findstr /i "update patch save" >nul
        if not errorlevel 1 set "SKIP_FILE=true"
        
        if "!SKIP_FILE!"=="false" (
            set /a "GAME_NUM+=1"
            set "GAME_PATH[!GAME_NUM!]=%%~dpnxf"
            set "GAME_NAME[!GAME_NUM!]=%%~nf"
            
            :: Display name with subfolder if not in main GBA folder
            set "DISPLAY_NAME=%%~nf [ZIP]"
            set "REL_PATH=%%~dpf"
            set "REL_PATH=!REL_PATH:%GBA_DIR%\=!"
            if not "!REL_PATH!"=="!GBA_DIR!" (
                if not "!REL_PATH!"=="" (
                    set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf [ZIP]"
                )
            )
            
            echo !GAME_NUM!. !DISPLAY_NAME!
        )
    )
) else if "%GAME_TYPE%"=="ISO" (
    :: List ISO files
    for /r "%ISO_DIR%" %%f in (*.iso *.bin *.cue *.img *.ccd) do (
        set /a "GAME_NUM+=1"
        set "GAME_PATH[!GAME_NUM!]=%%~dpnxf"
        set "GAME_NAME[!GAME_NUM!]=%%~nf"
:: Display name with subfolder if not in main ISO folder
        set "DISPLAY_NAME=%%~nf [%%~xf]"
        set "REL_PATH=%%~dpf"
        set "REL_PATH=!REL_PATH:%ISO_DIR%\=!"
        if not "!REL_PATH!"=="!ISO_DIR!" (
            if not "!REL_PATH!"=="" (
                set "DISPLAY_NAME=[!REL_PATH:~0,-1!] %%~nf [%%~xf]"
            )
        )
        
        echo !GAME_NUM!. !DISPLAY_NAME!
    )
)

echo.
echo 0. Back to Controller Setup
echo.

set /p game_choice="Enter game number: "

if "%game_choice%"=="0" goto ControllerSetup

:: Validate input
set /a game_num=%game_choice% 2>nul
if %game_num% lss 1 goto ConfigureGameController
if %game_num% gtr %GAME_NUM% goto ConfigureGameController

:: Create the controller profile
cls
echo ========================================================
echo              CREATING CONTROLLER PROFILE
echo ========================================================
echo.
echo Creating controller profile for: !GAME_NAME[%game_num%]!
echo.
echo Instructions:
echo 1. When JoyToKey opens, connect your controller
echo 2. Configure the buttons for this specific game
echo 3. Go to [File] menu and select [Save Configuration]
echo 4. The file will automatically be saved with the right name
echo.
echo Press any key to launch JoyToKey...
pause >nul

if not exist "%TOOLS_DIR%\JoyToKey\Profiles" mkdir "%TOOLS_DIR%\JoyToKey\Profiles"

:: First check if a default profile exists for this type of game to use as a starting point
set "DEFAULT_PROFILE="
if "%GAME_TYPE%"=="DOS" set "DEFAULT_PROFILE=%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg"
if "%GAME_TYPE%"=="GBA" set "DEFAULT_PROFILE=%TOOLS_DIR%\JoyToKey\Profiles\GBA.cfg"
if "%GAME_TYPE%"=="ISO" set "DEFAULT_PROFILE=%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg"

if exist "!DEFAULT_PROFILE!" (
    copy "!DEFAULT_PROFILE!" "%TOOLS_DIR%\JoyToKey\Profiles\!GAME_NAME[%game_num%]!.cfg" >nul
    start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\!GAME_NAME[%game_num%]!.cfg"
) else (
    start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\!GAME_NAME[%game_num%]!.cfg"
)

echo.
echo JoyToKey has been launched.
echo After saving your configuration, press any key to return...
pause >nul
goto ControllerSetup

:: =================== FAVORITES ===================
:Favorites
cls
echo ========================================================
echo                    FAVORITES
echo ========================================================
echo.

if not exist "%FAV_DIR%\favorites.txt" (
    echo You don't have any favorites yet!
    echo.
    echo To add favorites:
    echo 1. Go to "Play DOS Games", "Play GBA Games" or "Play CD-ROM Games"
    echo 2. Press F and select a game to mark as favorite
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

:: Count favorites
set "FAV_COUNT=0"
set "DOS_FAV_COUNT=0"
set "GBA_FAV_COUNT=0"
set "ISO_FAV_COUNT=0"

for /f "tokens=1,* delims==" %%a in ('type "%FAV_DIR%\favorites.txt"') do (
    if not "%%a:~0,1"==";" (
        set /a "FAV_COUNT+=1"
        set "FAV_TYPE[!FAV_COUNT!]=%%a"
        set "FAV_PATH[!FAV_COUNT!]=%%b"
        
        for /f "tokens=1,2 delims=:" %%x in ("%%a") do (
            set "FAV_GAME_TYPE[!FAV_COUNT!]=%%x"
            set "FAV_GAME_NAME[!FAV_COUNT!]=%%y"
        )
        
        if "!FAV_GAME_TYPE[%FAV_COUNT%]!"=="DOS" (
            set /a "DOS_FAV_COUNT+=1"
        ) else if "!FAV_GAME_TYPE[%FAV_COUNT%]!"=="GBA" (
            set /a "GBA_FAV_COUNT+=1"
        ) else if "!FAV_GAME_TYPE[%FAV_COUNT%]!"=="ISO" (
            set /a "ISO_FAV_COUNT+=1"
        )
    )
)

if %FAV_COUNT% equ 0 (
    echo No favorites found!
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    goto MainMenu
)

echo Your Favorite Games:
echo.

:: Display DOS game favorites first
if %DOS_FAV_COUNT% gtr 0 (
    echo DOS GAMES:
    echo.
    
    set "COUNTER=0"
    for /l %%i in (1,1,%FAV_COUNT%) do (
        if "!FAV_GAME_TYPE[%%i]!"=="DOS" (
            set /a "COUNTER+=1"
            
            :: Check if save exists and add indicator
            set "SAVE_EXISTS="
            if exist "%SAVE_DIR%\dos\!FAV_GAME_NAME[%%i]!\*.sav" set "SAVE_EXISTS=[SAVE]"
            
            :: Check if it's a ZIP file
            set "IS_ZIP="
            if "!FAV_PATH[%%i]:~-4!"==".zip" set "IS_ZIP=[ZIP]"
            
            :: Check playtime
            set "PLAYTIME="
            if exist "%PLAYTIME_FILE%" (
                for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%" ^| findstr /i "^!FAV_GAME_NAME[%%i]!="') do (
                    set /a "HOURS=%%b/60"
                    set /a "MINS=%%b%%60"
                    if !HOURS! gtr 0 (
                        set "PLAYTIME=[!HOURS!h !MINS!m]"
                    ) else (
                        set "PLAYTIME=[!MINS!m]"
                    )
                )
            )
            
            echo D!COUNTER!. !FAV_GAME_NAME[%%i]! !IS_ZIP! !SAVE_EXISTS! !PLAYTIME!
        )
    )
    
    echo.
)

:: Display GBA ROM favorites
if %GBA_FAV_COUNT% gtr 0 (
    echo GBA GAMES:
    echo.
    
    set "COUNTER=0"
    for /l %%i in (1,1,%FAV_COUNT%) do (
        if "!FAV_GAME_TYPE[%%i]!"=="GBA" (
            set /a "COUNTER+=1"
            
            :: Check if save exists and add indicator
            set "SAVE_EXISTS="
            if exist "%SAVE_DIR%\gba\!FAV_GAME_NAME[%%i]!.sav" set "SAVE_EXISTS=[SAVE]"
            
            :: Check if it's a ZIP file
            set "IS_ZIP="
            if "!FAV_PATH[%%i]:~-4!"==".zip" set "IS_ZIP=[ZIP]"
            
            :: Check playtime
            set "PLAYTIME="
            if exist "%PLAYTIME_FILE%" (
                for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%" ^| findstr /i "^!FAV_GAME_NAME[%%i]!="') do (
                    set /a "HOURS=%%b/60"
                    set /a "MINS=%%b%%60"
                    if !HOURS! gtr 0 (
                        set "PLAYTIME=[!HOURS!h !MINS!m]"
                    ) else (
                        set "PLAYTIME=[!MINS!m]"
                    )
                )
            )
            
            echo G!COUNTER!. !FAV_GAME_NAME[%%i]! !IS_ZIP! !SAVE_EXISTS! !PLAYTIME!
        )
    )
    
    echo.
)

:: Display ISO favorites
if %ISO_FAV_COUNT% gtr 0 (
    echo CD-ROM GAMES:
    echo.
    
    set "COUNTER=0"
    for /l %%i in (1,1,%FAV_COUNT%) do (
        if "!FAV_GAME_TYPE[%%i]!"=="ISO" (
            set /a "COUNTER+=1"
            
            :: Check if save exists and add indicator
            set "SAVE_EXISTS="
            if exist "%SAVE_DIR%\dos\!FAV_GAME_NAME[%%i]!\*.sav" set "SAVE_EXISTS=[SAVE]"
            
            :: Get file extension
            for %%x in ("!FAV_PATH[%%i]!") do set "ISO_EXT=[%%~xx]"
            
            :: Check playtime
            set "PLAYTIME="
            if exist "%PLAYTIME_FILE%" (
                for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%" ^| findstr /i "^!FAV_GAME_NAME[%%i]!="') do (
                    set /a "HOURS=%%b/60"
                    set /a "MINS=%%b%%60"
                    if !HOURS! gtr 0 (
                        set "PLAYTIME=[!HOURS!h !MINS!m]"
                    ) else (
                        set "PLAYTIME=[!MINS!m]"
                    )
                )
            )
            
            echo I!COUNTER!. !FAV_GAME_NAME[%%i]! !ISO_EXT! !SAVE_EXISTS! !PLAYTIME!
        )
    )
    
    echo.
)

echo Enter D# to play a DOS game favorite (e.g., D1)
echo Enter G# to play a GBA game favorite (e.g., G1)
echo Enter I# to play a CD-ROM favorite (e.g., I1)
echo Or enter 0 to return to main menu
echo.

set /p fav_choice="Enter choice: "

if "%fav_choice%"=="0" goto MainMenu

:: Parse the choice - DOS game
set "PREFIX=%fav_choice:~0,1%"
set "NUMBER=%fav_choice:~1%"

if /i "%PREFIX%"=="D" (
    set /a num=%NUMBER% 2>nul
    
    if %num% lss 1 goto Favorites
    if %num% gtr %DOS_FAV_COUNT% goto Favorites
    
    :: Find the corresponding DOS game
    set "COUNTER=0"
    set "TARGET_PATH="
    set "TARGET_NAME="
    set "TARGET_DIR="
    set "IS_ZIP=false"
    
    for /l %%i in (1,1,%FAV_COUNT%) do (
        if "!FAV_GAME_TYPE[%%i]!"=="DOS" (
            set /a "COUNTER+=1"
            if !COUNTER! equ %num% (
                set "TARGET_PATH=!FAV_PATH[%%i]!"
                set "TARGET_NAME=!FAV_GAME_NAME[%%i]!"
                for %%p in ("!TARGET_PATH!") do set "TARGET_DIR=%%~dpp"
                for %%p in ("!TARGET_PATH!") do set "TARGET_FILE=%%~nxp"
                
                :: Check if it's a ZIP file
                if "!TARGET_PATH:~-4!"==".zip" set "IS_ZIP=true"
            )
        )
    )
    
    :: Check if file exists
    if not exist "!TARGET_PATH!" (
        echo Error: Game file not found at !TARGET_PATH!
        echo.
        echo Press any key to return to favorites...
        pause >nul
        goto Favorites
    )
    
    :: Start tracking playtime
    call :StartTimeTracking
    
    :: Launch the favorite DOS game with DOSBox-X
    cls
    echo ========================================================
    echo                LAUNCHING FAVORITE DOS GAME
    echo ========================================================
    echo.
    echo Launching: !TARGET_NAME!
    echo Path: !TARGET_PATH!
    echo Using DOSBox-X from: %DOSBOX_PATH%
    echo.
    
    :: Start JoyToKey if it exists and has a profile
    if "%JOYTOKEY_FOUND%"=="true" (
        if exist "%TOOLS_DIR%\JoyToKey\Profiles\!TARGET_NAME!.cfg" (
            echo Starting JoyToKey with game-specific profile...
            start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\!TARGET_NAME!.cfg"
        ) else if exist "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg" (
            echo Starting JoyToKey with default DOSBox profile...
            start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg"
        ) else (
            echo Starting JoyToKey with default profile...
            start "" "%JOYTOKEY_PATH%"
        )
    )
    
    :: Create a game-specific save folder if needed
    set "GAME_SAVE_DIR=%SAVE_DIR%\dos\!TARGET_NAME!"
    if not exist "%GAME_SAVE_DIR%" mkdir "%GAME_SAVE_DIR%"
:: Check if it's a ZIP file that needs extraction
    if "!IS_ZIP!"=="true" (
        echo Extracting game files from ZIP...
        
        :: Create temporary directory for extraction
        set "EXTRACT_DIR=%TEMP_DIR%\!TARGET_NAME!"
        if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!"
        mkdir "!EXTRACT_DIR!"
        
        :: Create a safe path version without special characters
        set "SAFE_PATH=!TARGET_PATH!"
        set "SAFE_PATH=!SAFE_PATH:&=^&!"
        set "SAFE_PATH=!SAFE_PATH:(=^(!"
        set "SAFE_PATH=!SAFE_PATH:)=^)!"
        set "SAFE_PATH=!SAFE_PATH:>=^>!"
        set "SAFE_PATH=!SAFE_PATH:<=^<!"
        set "SAFE_PATH=!SAFE_PATH:|=^|!"
        
        :: Extract ZIP file with error handling
        echo Using PowerShell to extract files...
        powershell -command "try { Expand-Archive -LiteralPath '!SAFE_PATH!' -DestinationPath '!EXTRACT_DIR!' -Force } catch { exit 1 }" >nul 2>&1
        if errorlevel 1 (
            echo PowerShell extraction failed, trying alternate methods...
            
            :: Try 7-Zip if available
            if exist "%EMULATORS_DIR%\7z.exe" (
                "%EMULATORS_DIR%\7z.exe" x -y "!TARGET_PATH!" -o"!EXTRACT_DIR!" >nul
            ) else if exist "%UNZIP_PATH%" (
                "%UNZIP_PATH%" x -y "!TARGET_PATH!" -o"!EXTRACT_DIR!" >nul
            ) else {
                echo Unable to extract ZIP file: format not supported
                echo Please install 7-Zip in the emulators folder for better ZIP support
                goto ErrorHandler
            }
        )
        
        echo Extraction complete. Finding main executable...
        
        :: List all files for debugging
        echo Files found in extraction:
        dir /b /s "!EXTRACT_DIR!" | findstr /i "\.exe \.com \.bat"
        echo.
        
        :: Find ANY executable in the extracted folder (not just common names)
        set "FOUND_EXE=false"
        set "EXTRACT_EXE="
        set "EXTRACT_SUBDIR="
        
        :: Use a more comprehensive approach to find a suitable executable
        :: First pass: Look for .exe files in root directory that aren't common utilities
        for %%f in ("!EXTRACT_DIR!\*.exe") do (
            if "!FOUND_EXE!"=="false" (
                :: Skip known setup/utility executables
                set "UTILITY=false"
                for %%u in (setup install config unins readme help) do (
                    if /i "%%~nf"=="%%u" set "UTILITY=true"
                )
                
                :: If not a utility, use it
                if "!UTILITY!"=="false" (
                    set "FOUND_EXE=true"
                    set "EXTRACT_EXE=%%~nxf"
                    set "EXTRACT_SUBDIR=%%~dpf"
                    echo Found game executable: %%~nxf in root folder
                )
            )
        )
        
        :: Second pass: Look for .exe files in any subfolder if not found yet
        if "!FOUND_EXE!"=="false" (
            for /r "!EXTRACT_DIR!" %%f in (*.exe) do (
                if "!FOUND_EXE!"=="false" (
                    :: Skip known setup files
                    set "UTILITY=false"
                    for %%u in (setup install config unins readme help) do (
                        if /i "%%~nf"=="%%u" set "UTILITY=true"
                    )
                    
                    :: Also check if name contains these strings
                    echo "%%~nf" | findstr /i "setup install config unins readme help" >nul
                    if not errorlevel 1 set "UTILITY=true"
                    
                    :: If not a utility, use it
                    if "!UTILITY!"=="false" (
                        set "FOUND_EXE=true"
                        set "EXTRACT_EXE=%%~nxf"
                        set "EXTRACT_SUBDIR=%%~dpf"
                        echo Found game executable: %%~nxf in subfolder
                    )
                )
            )
        )
        
        :: Try .com files as a last resort
        if "!FOUND_EXE!"=="false" (
            for /r "!EXTRACT_DIR!" %%f in (*.com) do (
                if "!FOUND_EXE!"=="false" (
                    set "FOUND_EXE=true"
                    set "EXTRACT_EXE=%%~nxf"
                    set "EXTRACT_SUBDIR=%%~dpf"
                    echo Found executable: %%~nxf
                )
            )
        )
        
        if "!FOUND_EXE!"=="false" (
            echo No executable found in the ZIP archive.
            echo.
            echo Files in extracted folder:
            dir /s /b "!EXTRACT_DIR!"
            echo.
            echo Press any key to return to favorites...
            pause >nul
            goto Favorites
        )
        
        echo Auto-save is enabled. Game will auto-save every 3 minutes.
        echo Press CTRL+F4 for quick save or F9 for quick load during gameplay.
        echo.
        echo When you're done playing, the launcher will return.
        echo.
        timeout /t 3 >nul
        
        :: Remove quotes from paths to avoid syntax errors
        set "MOUNT_PATH=!EXTRACT_SUBDIR!"
        set "MOUNT_PATH=!MOUNT_PATH:"=!"
        
        :: Check for path length limits
        set "PATH_LENGTH=0"
        set "PATH_TO_CHECK=!MOUNT_PATH!!EXTRACT_EXE!"
        for %%p in ("!PATH_TO_CHECK!") do set "PATH_LENGTH=%%~zp"
        
        if !PATH_LENGTH! gtr 240 (
            echo WARNING: Path is very long and may cause issues.
            echo Using short path names to mitigate...
            
            :: Use short path names when paths are too long
            for %%i in ("!MOUNT_PATH!") do set "MOUNT_PATH=%%~si"
            for %%i in ("!EXTRACT_EXE!") do set "EXTRACT_EXE=%%~si"
        )
        
        :: Launch DOSBox with proper command line
        call :SafeLaunch "%DOSBOX_PATH%" -conf "%DOSBOX_CONF%" -c "mount c \"!MOUNT_PATH!\"" -c "c:" -c "!EXTRACT_EXE!" -savedir "%GAME_SAVE_DIR%"
        
    ) else (
        :: Regular executable file
        echo Auto-save is enabled. Game will auto-save every 3 minutes.
        echo Press CTRL+F4 for quick save or F9 for quick load during gameplay.
        echo.
        echo When you're done playing, the launcher will return.
        echo.
        timeout /t 3 >nul
        
        :: Remove quotes from paths to avoid syntax errors
        set "MOUNT_PATH=!TARGET_DIR!"
        set "MOUNT_PATH=!MOUNT_PATH:"=!"
        set "GAME_EXEC=!TARGET_FILE!"
        
        :: Check for path length limits
        set "PATH_LENGTH=0"
        set "PATH_TO_CHECK=!MOUNT_PATH!!GAME_EXEC!"
        for %%p in ("!PATH_TO_CHECK!") do set "PATH_LENGTH=%%~zp"
        
        if !PATH_LENGTH! gtr 240 (
            echo WARNING: Path is very long and may cause issues.
            echo Using short path names to mitigate...
            
            :: Use short path names when paths are too long
            for %%i in ("!MOUNT_PATH!") do set "MOUNT_PATH=%%~si"
            for %%i in ("!GAME_EXEC!") do set "GAME_EXEC=%%~si"
        )
        
        :: Launch DOSBox with correct command line
        call :SafeLaunch "%DOSBOX_PATH%" -conf "%DOSBOX_CONF%" -c "mount c \"!MOUNT_PATH!\"" -c "c:" -c "!GAME_EXEC!" -savedir "%GAME_SAVE_DIR%"
    )
    
    :: End tracking and update playtime
    call :EndTimeTracking
    
    echo Game finished! Press any key to return to the menu...
    pause >nul
    goto MainMenu
)

:: Parse the choice - GBA game
if /i "%PREFIX%"=="G" (
    set /a num=%NUMBER% 2>nul
    
    if %num% lss 1 goto Favorites
    if %num% gtr %GBA_FAV_COUNT% goto Favorites
    
    :: Find the corresponding GBA ROM
    set "COUNTER=0"
    set "TARGET_PATH="
    set "TARGET_NAME="
    set "IS_ZIP=false"
    
    for /l %%i in (1,1,%FAV_COUNT%) do (
        if "!FAV_GAME_TYPE[%%i]!"=="GBA" (
            set /a "COUNTER+=1"
            if !COUNTER! equ %num% (
                set "TARGET_PATH=!FAV_PATH[%%i]!"
                set "TARGET_NAME=!FAV_GAME_NAME[%%i]!"
                
                :: Check if it's a ZIP file
                if "!TARGET_PATH:~-4!"==".zip" set "IS_ZIP=true"
            )
        )
    )
    
    :: Check if file exists
    if not exist "!TARGET_PATH!" (
        echo Error: ROM file not found at !TARGET_PATH!
        echo.
        echo Press any key to return to favorites...
        pause >nul
        goto Favorites
    )
    
    :: Check for GBA emulator
    if "%GBA_EMU_FOUND%"=="false" (
        echo No GBA emulator found!
        echo.
        echo Press any key to return to favorites...
        pause >nul
        goto Favorites
    )
    
    :: Start tracking playtime
    call :StartTimeTracking
    
    :: Launch the favorite GBA ROM
    cls
    echo ========================================================
    echo                LAUNCHING FAVORITE GBA GAME
    echo ========================================================
    echo.
    echo Launching: !TARGET_NAME!
    echo Path: !TARGET_PATH!
    echo Using emulator: %GBA_EMU_PATH%
    echo.
    
    :: Start JoyToKey if it exists and has a profile
    if "%JOYTOKEY_FOUND%"=="true" (
        if exist "%TOOLS_DIR%\JoyToKey\Profiles\!TARGET_NAME!.cfg" (
            echo Starting JoyToKey with game-specific profile...
            start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\!TARGET_NAME!.cfg"
        ) else if exist "%TOOLS_DIR%\JoyToKey\Profiles\GBA.cfg" (
            echo Starting JoyToKey with default GBA profile...
            start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\GBA.cfg"
        ) else (
            echo Starting JoyToKey with default profile...
            start "" "%JOYTOKEY_PATH%"
        )
    )
    
    :: Check if it's a ZIP file
    if "!IS_ZIP!"=="true" (
        :: For ZIP files, try emulator's direct ZIP support if available
        set "DIRECT_ZIP=false"
        if /i "%GBA_EMU_NAME%"=="mGBA" set "DIRECT_ZIP=true"
        
        if "!DIRECT_ZIP!"=="true" (
            echo This emulator supports direct ZIP loading. Launching from ZIP...
            
            :: Create save directory if it doesn't exist
            if not exist "%SAVE_DIR%\gba" mkdir "%SAVE_DIR%\gba"
            
            :: Determine emulator-specific save options
            set "SAVE_ARGS="
            
            if /i "%GBA_EMU_NAME%"=="mGBA" (
                set "SAVE_ARGS=-s "%SAVE_DIR%\gba\!TARGET_NAME!.sav""
            )
            
            echo.
            echo Save files will be stored in:
            echo %SAVE_DIR%\gba\
            echo.
            echo When you're done playing, close the emulator window.
            echo.
            timeout /t 3 >nul
            
            :: Launch the emulator with the ZIP file directly
            call :SafeLaunch start "" "%GBA_EMU_PATH%" !SAVE_ARGS! "!TARGET_PATH!"
            
        ) else (
            echo Extracting ROM from ZIP archive...
            
            :: Create temporary directory for extraction
            set "EXTRACT_DIR=%TEMP_DIR%\!TARGET_NAME!"
            if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!"
            mkdir "!EXTRACT_DIR!"
            
            :: Create a safe path version without special characters
            set "SAFE_PATH=!TARGET_PATH!"
            set "SAFE_PATH=!SAFE_PATH:&=^&!"
            set "SAFE_PATH=!SAFE_PATH:(=^(!"
            set "SAFE_PATH=!SAFE_PATH:)=^)!"
            set "SAFE_PATH=!SAFE_PATH:>=^>!"
            set "SAFE_PATH=!SAFE_PATH:<=^<!"
            set "SAFE_PATH=!SAFE_PATH:|=^|!"
            
            :: Extract ZIP file with error handling
            echo Using PowerShell to extract files...
            powershell -command "try { Expand-Archive -LiteralPath '!SAFE_PATH!' -DestinationPath '!EXTRACT_DIR!' -Force } catch { exit 1 }" >nul 2>&1
            if errorlevel 1 (
                echo PowerShell extraction failed, trying alternate methods...
                
                :: Try 7-Zip if available
                if exist "%EMULATORS_DIR%\7z.exe" (
                    "%EMULATORS_DIR%\7z.exe" x -y "!TARGET_PATH!" -o"!EXTRACT_DIR!" >nul
                ) else if exist "%UNZIP_PATH%" (
                    "%UNZIP_PATH%" x -y "!TARGET_PATH!" -o"!EXTRACT_DIR!" >nul
                ) else {
                    echo Unable to extract ZIP file: format not supported
                    echo Please install 7-Zip in the emulators folder for better ZIP support
                    goto ErrorHandler
                }
            )
            
            echo Extraction complete. Searching for GBA ROMs...
            echo.
            
            :: Debug output - list the contents of extracted directory
            echo Files found in extraction directory:
            dir /b "!EXTRACT_DIR!" | findstr /i "\.gba$"
            echo.
            
            :: Find GBA ROM in the extracted directory
            set "FOUND_ROM=false"
            set "EXTRACT_ROM="
            
            :: First try ROM with same name as ZIP
            if exist "!EXTRACT_DIR!\!TARGET_NAME!.gba" (
                set "FOUND_ROM=true"
                set "EXTRACT_ROM=!EXTRACT_DIR!\!TARGET_NAME!.gba"
                echo Found matching GBA ROM: !TARGET_NAME!.gba
            )
            
            :: If not found, search all subdirectories
            if "!FOUND_ROM!"=="false" (
                for /r "!EXTRACT_DIR!" %%g in (*.gba) do (
                    if "!FOUND_ROM!"=="false" (
                        set "FOUND_ROM=true"
                        set "EXTRACT_ROM=%%~dpnxg"
                        echo Found GBA ROM: %%~nxg
                    )
                )
            )
            
            if "!FOUND_ROM!"=="false" (
                echo No GBA ROM found in the ZIP archive.
                echo Contents of extracted folder:
                dir /s /b "!EXTRACT_DIR!"
                echo.
                echo Press any key to return to favorites...
                pause >nul
                goto Favorites
            )
            
            :: Create save directory if it doesn't exist
            if not exist "%SAVE_DIR%\gba" mkdir "%SAVE_DIR%\gba"
            
            :: Determine emulator-specific save options
            set "SAVE_ARGS="
            
            if /i "%GBA_EMU_NAME%"=="VisualBoyAdvance" (
                set "SAVE_ARGS=--battery-dir "%SAVE_DIR%\gba""
            ) else if /i "%GBA_EMU_NAME%"=="mGBA" (
                set "SAVE_ARGS=-s "%SAVE_DIR%\gba\!TARGET_NAME!.sav""
            ) else if /i "%GBA_EMU_NAME%"=="VBA" (
                set "SAVE_ARGS=--battery-dir "%SAVE_DIR%\gba""
            )
            
            echo.
            echo Save files will be stored in:
            echo %SAVE_DIR%\gba\
            echo.
            echo When you're done playing, close the emulator window.
            echo.
            timeout /t 3 >nul
:: Launch the emulator with the extracted ROM
            call :SafeLaunch start "" "%GBA_EMU_PATH%" !SAVE_ARGS! "!EXTRACT_ROM!"
        )
    ) else (
        :: Regular GBA file
        :: Create save directory if it doesn't exist
        if not exist "%SAVE_DIR%\gba" mkdir "%SAVE_DIR%\gba"
        
        :: Determine emulator-specific save options
        set "SAVE_ARGS="
        
        if /i "%GBA_EMU_NAME%"=="VisualBoyAdvance" (
            set "SAVE_ARGS=--battery-dir "%SAVE_DIR%\gba""
        ) else if /i "%GBA_EMU_NAME%"=="mGBA" (
            set "SAVE_ARGS=-s "%SAVE_DIR%\gba\!TARGET_NAME!.sav""
        ) else if /i "%GBA_EMU_NAME%"=="VBA" (
            set "SAVE_ARGS=--battery-dir "%SAVE_DIR%\gba""
        )
        
        echo Save files will be stored in:
        echo %SAVE_DIR%\gba\
        echo.
        echo When you're done playing, close the emulator window.
        echo.
        timeout /t 3 >nul
        
        :: Launch with the emulator using the exact path
        call :SafeLaunch start "" "%GBA_EMU_PATH%" !SAVE_ARGS! "!TARGET_PATH!"
    )
    
    :: Wait for emulator to close
    echo Game launched! Press any key AFTER closing the emulator to return to the menu...
    pause >nul
    
    :: End tracking and update playtime
    call :EndTimeTracking
    
    goto MainMenu
)

:: Parse the choice - ISO game
if /i "%PREFIX%"=="I" (
    set /a num=%NUMBER% 2>nul
    
    if %num% lss 1 goto Favorites
    if %num% gtr %ISO_FAV_COUNT% goto Favorites
    
    :: Find the corresponding ISO file
    set "COUNTER=0"
    set "TARGET_PATH="
    set "TARGET_NAME="
    set "TARGET_EXT="
    
    for /l %%i in (1,1,%FAV_COUNT%) do (
        if "!FAV_GAME_TYPE[%%i]!"=="ISO" (
            set /a "COUNTER+=1"
            if !COUNTER! equ %num% (
                set "TARGET_PATH=!FAV_PATH[%%i]!"
                set "TARGET_NAME=!FAV_GAME_NAME[%%i]!"
                for %%p in ("!TARGET_PATH!") do set "TARGET_EXT=%%~xp"
            )
        )
    )
    
    :: Check if file exists
    if not exist "!TARGET_PATH!" (
        echo Error: ISO file not found at !TARGET_PATH!
        echo.
        echo Press any key to return to favorites...
        pause >nul
        goto Favorites
    )
    
    :: Start tracking playtime
    call :StartTimeTracking
    
    :: Launch the ISO with DOSBox-X
    cls
    echo ========================================================
    echo                LAUNCHING FAVORITE CD-ROM GAME
    echo ========================================================
    echo.
    echo Launching: !TARGET_NAME!!TARGET_EXT!
    echo Path: !TARGET_PATH!
    echo Using DOSBox-X from: %DOSBOX_PATH%
    echo.
    echo Auto-save is enabled. Game will auto-save every 3 minutes.
    echo Press CTRL+F4 for quick save or F9 for quick load during gameplay.
    echo.
    echo When you're done playing, the launcher will return.
    echo.
    timeout /t 3 >nul
    
    :: Start JoyToKey if it exists and has a profile
    if "%JOYTOKEY_FOUND%"=="true" (
        if exist "%TOOLS_DIR%\JoyToKey\Profiles\!TARGET_NAME!.cfg" (
            echo Starting JoyToKey with game-specific profile...
            start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\!TARGET_NAME!.cfg"
        ) else if exist "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg" (
            echo Starting JoyToKey with default DOSBox profile...
            start "" "%JOYTOKEY_PATH%" -cfg "%TOOLS_DIR%\JoyToKey\Profiles\DOSBox.cfg"
        ) else (
            echo Starting JoyToKey with default profile...
            start "" "%JOYTOKEY_PATH%"
        )
    )
    
    :: Create a game-specific save folder if needed
    set "ISO_SAVE_DIR=%SAVE_DIR%\dos\!TARGET_NAME!"
    if not exist "%ISO_SAVE_DIR%" mkdir "%ISO_SAVE_DIR%"
    
    :: Create temporary C: drive directory if it doesn't exist
    set "TEMP_C_DIR=%TEMP_DIR%\!TARGET_NAME!"
    if not exist "!TEMP_C_DIR!" mkdir "!TEMP_C_DIR!"
    
    :: Remove quotes from paths to avoid syntax errors
    set "ISO_CLEAN_PATH=!TARGET_PATH!"
    set "ISO_CLEAN_PATH=!ISO_CLEAN_PATH:"=!"
    
    :: Determine the proper imgmount parameters based on file extension
    set "ISO_TYPE=iso"
    if /i "!TARGET_EXT!"==".bin" set "ISO_TYPE=cue"
    if /i "!TARGET_EXT!"==".cue" set "ISO_TYPE=cue"
    if /i "!TARGET_EXT!"==".ccd" set "ISO_TYPE=cue"
    if /i "!TARGET_EXT!"==".img" (
        :: Check if it's a CD image or a floppy image
        for %%f in ("!TARGET_PATH!") do set "FILE_SIZE=%%~zf"
        if !FILE_SIZE! gtr 2000000 (
            set "ISO_TYPE=iso"
        ) else (
            set "ISO_TYPE=floppy"
        )
    )
    
    :: Check for path length limits
    set "PATH_LENGTH=0"
    set "PATH_TO_CHECK=!ISO_CLEAN_PATH!"
    for %%p in ("!PATH_TO_CHECK!") do set "PATH_LENGTH=%%~zp"
    
    if !PATH_LENGTH! gtr 240 (
        echo WARNING: Path is very long and may cause issues.
        echo Using short path names to mitigate...
        
        :: Use short path names when paths are too long
        for %%i in ("!ISO_CLEAN_PATH!") do set "ISO_CLEAN_PATH=%%~si"
    )
    
    :: Mount with the appropriate type
    if "!ISO_TYPE!"=="floppy" (
        call :SafeLaunch "%DOSBOX_PATH%" -conf "%DOSBOX_CONF%" -c "mount c \"!TEMP_C_DIR!\"" -c "imgmount a \"!ISO_CLEAN_PATH!\" -t !ISO_TYPE!" -c "a:" -c "dir" -savedir "%ISO_SAVE_DIR%"
    ) else (
        call :SafeLaunch "%DOSBOX_PATH%" -conf "%DOSBOX_CONF%" -c "mount c \"!TEMP_C_DIR!\"" -c "imgmount d \"!ISO_CLEAN_PATH!\" -t !ISO_TYPE!" -c "d:" -c "dir" -savedir "%ISO_SAVE_DIR%"
    )
    
    :: End tracking and update playtime
    call :EndTimeTracking
    
    echo Game finished! Press any key to return to the menu...
    pause >nul
    goto MainMenu
)

echo Invalid choice! Press any key to try again...
pause >nul
goto Favorites

:: =================== CHECK FOR UPDATES ===================
:CheckForUpdates
cls
echo ========================================================
echo                   UPDATE CHECKER
echo ========================================================
echo.
echo Checking for launcher updates...
echo.

:: Define update information
set "CURRENT_VERSION=%LAUNCHER_VERSION%"
set "VERSION_FILE=%ROOT_DIR%version.txt"
set "UPDATE_INFO=%ROOT_DIR%update_info.txt"

:: Create version file if it doesn't exist
if not exist "%VERSION_FILE%" (
    echo %CURRENT_VERSION% > "%VERSION_FILE%"
    echo Initialized version tracking.
)

:: Check for internet connectivity (basic test)
ping github.com -n 1 -w 1000 >nul
if %errorlevel% neq 0 (
    echo No internet connection detected.
    echo Update check skipped.
    echo.
    timeout /t 2 >nul
    goto :eof
)

:: Check for updates from the GitHub repository
echo Connecting to update server...

:: Try to download version info
if exist "%TEMP%\version_check.txt" del "%TEMP%\version_check.txt"
curl -s https://raw.githubusercontent.com/rbt4/launcher/main/version.txt -o "%TEMP%\version_check.txt" >nul 2>&1

:: Check if download successful
if not exist "%TEMP%\version_check.txt" (
    echo Unable to check for updates. Server might be unavailable.
    echo.
    timeout /t 2 >nul
    goto :eof
)

:: Read version info
set /p NEW_VER=<"%TEMP%\version_check.txt"
set /p CURRENT_VER=<"%VERSION_FILE%"

echo Current version: %CURRENT_VER%
echo Latest version: %NEW_VER%
echo.

:: Create update info file
> "%UPDATE_INFO%" echo %NEW_VER%

if "%CURRENT_VER%" neq "%NEW_VER%" (
    echo An update is available!
    echo.
    echo Changes in version %NEW_VER%:
    
    :: Try to download changelog
    curl -s https://raw.githubusercontent.com/rbt4/launcher/main/changelog.txt -o "%TEMP%\changelog.txt" >nul 2>&1
    
    if exist "%TEMP%\changelog.txt" (
        type "%TEMP%\changelog.txt"
    ) else (
        echo - Unable to retrieve changelog
    )
    
    echo.
    echo Would you like to update the launcher now?
    set /p update_now="Type YES to update: "
    
    if /i "%update_now%"=="YES" (
        echo.
        echo Downloading update...
        
        :: Create backup of current script
        copy "%~f0" "%~f0.bak" >nul
        
        :: Download new version
        curl -s https://raw.githubusercontent.com/rbt4/launcher/main/launcher.bat -o "%TEMP%\new_launcher.bat" >nul 2>&1
        
        if exist "%TEMP%\new_launcher.bat" (
            echo Applying update...
            
            :: Replace the current script with the new one
            copy /y "%TEMP%\new_launcher.bat" "%~f0" >nul
            
            echo Update completed successfully!
            echo.
            echo Press any key to restart the launcher...
            pause >nul
            
            :: Restart the launcher
            start "" "%~f0"
            exit
        ) else (
            echo Failed to download update.
            echo Please check your internet connection and try again.
        )
    )
) else (
    echo You are running the latest version!
)

echo.
echo Press any key to return to the main menu...
pause >nul
goto MainMenu

:: =================== EXIT ===================
:Exit
:: Check if auto-backup is enabled
set "AUTO_BACKUP=false"
set "AUTO_BACKUP_CONFIG=%ROOT_DIR%auto_backup.cfg"

if exist "%AUTO_BACKUP_CONFIG%" (
    for /f "tokens=1,* delims==" %%a in ('type "%AUTO_BACKUP_CONFIG%"') do (
        if "%%a"=="AutoBackup" set "AUTO_BACKUP=%%b"
    )
)

if "%AUTO_BACKUP%"=="true" (
    echo Performing auto-backup before exit...
    
    :: Quick backup process
    set "BACKUP_DIR=%ROOT_DIR%backups"
    if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
    
    :: Create timestamp for backup folder
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set "DATE=%%c-%%a-%%b")
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do (set "TIME=%%a%%b")
    set "BACKUP_NAME=backup_%DATE%_%TIME%_AutoExit"
    set "BACKUP_PATH=%BACKUP_DIR%\%BACKUP_NAME%"
    mkdir "%BACKUP_PATH%"
    
    :: Backup saves and config
    if exist "%SAVE_DIR%\dos" xcopy /s /i /y "%SAVE_DIR%\dos" "%BACKUP_PATH%\dos" >nul
    if exist "%SAVE_DIR%\gba" xcopy /s /i /y "%SAVE_DIR%\gba" "%BACKUP_PATH%\gba" >nul
    if exist "%ROOT_DIR%\*.dat" xcopy /y "%ROOT_DIR%\*.dat" "%BACKUP_PATH%\" >nul
    if exist "%ROOT_DIR%\*.txt" xcopy /y "%ROOT_DIR%\*.txt" "%BACKUP_PATH%\" >nul
    
    :: Log the auto-backup
    echo %DATE% %TIME% - Auto-Exit Backup created: %BACKUP_NAME% >> "%BACKUP_DIR%\backup_history.log"
    
    echo Auto-backup completed!
    echo.
)

:: Close any JoyToKey instances that might be running
if "%JOYTOKEY_FOUND%"=="true" (
    taskkill /f /im JoyToKey.exe >nul 2>&1
)

echo Thank you for using the Ultimate Kids Game Launcher!
echo Have a great day!
echo.
echo Exiting in 3 seconds...
timeout /t 3 >nul
exit

:: =================== ERROR HANDLER ===================
:ErrorHandler
echo.
echo ========================================================
echo                     ERROR DETECTED
echo ========================================================
echo.
echo An error occurred during the operation.
echo Error details have been logged to: %ERROR_LOG%
echo.
echo Press any key to return to the main menu...

:: Log the error
echo %DATE% %TIME% - Error during operation >> "%ERROR_LOG%"
echo Last command: %0 %* >> "%ERROR_LOG%"
echo Current directory: %CD% >> "%ERROR_LOG%"
echo. >> "%ERROR_LOG%"

pause >nul
goto MainMenu

:: =================== PLAYTIME TRACKING FUNCTIONS ===================
:StartTimeTracking
:: Get the current time in seconds since midnight
for /f "tokens=1-3 delims=:." %%a in ('echo %time%') do (
    set /a "START_TIME=(%%a*3600 + %%b*60 + %%c) + 0"
)
goto :eof

:EndTimeTracking
:: Calculate the elapsed time
for /f "tokens=1-3 delims=:., " %%a in ('echo %time%') do (
    set /a "END_TIME=(%%a*3600 + %%b*60 + %%c) + 0"
)

:: Handle midnight crossing
if %END_TIME% lss %START_TIME% set /a "END_TIME+=86400"

set /a "ELAPSED_TIME=(%END_TIME% - %START_TIME%) / 60 + 1"

:: Update the playtime data
if "%GAME_TYPE%"=="GBA" (
    set "GAME_TO_UPDATE=!ROM_NAME[%rom_num%]!"
) else if "%GAME_TYPE%"=="ZIP" (
    set "GAME_TO_UPDATE=!GAME_NAME[%game_num%]!"
) else if "%GAME_TYPE%"=="ISO" (
    set "GAME_TO_UPDATE=!ISO_NAME[%iso_num%]!"
) else (
    set "GAME_TO_UPDATE=!GAME_NAME[%game_num%]!"
)

:: If launched from favorites, use the favorite name
if "%TARGET_NAME%" neq "" set "GAME_TO_UPDATE=%TARGET_NAME%"

echo Updating playtime for !GAME_TO_UPDATE! ^(+!ELAPSED_TIME! minutes^)

:: Update the playtime file
set "TEMP_FILE=%TEMP%\playtime_temp.dat"
set "FOUND=false"

if exist "%PLAYTIME_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%PLAYTIME_FILE%"') do (
        if "%%a"=="!GAME_TO_UPDATE!" (
            set /a "NEW_TIME=%%b + %ELAPSED_TIME%"
            echo !GAME_TO_UPDATE!=!NEW_TIME!>> "%TEMP_FILE%"
            set "FOUND=true"
        ) else (
            echo %%a=%%b>> "%TEMP_FILE%"
        )
    )
)

if "%FOUND%"=="false" (
    echo !GAME_TO_UPDATE!=%ELAPSED_TIME%>> "%TEMP_FILE%"
)

if exist "%TEMP_FILE%" (
    copy /y "%TEMP_FILE%" "%PLAYTIME_FILE%" >nul
    del "%TEMP_FILE%" >nul
) else (
    echo !GAME_TO_UPDATE!=%ELAPSED_TIME%> "%PLAYTIME_FILE%"
)

:: Update recent games file
set "TEMP_FILE=%TEMP%\recent_temp.dat"
set "FOUND=false"

if exist "%RECENT_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%RECENT_FILE%"') do (
        if "%%a"=="!GAME_TO_UPDATE!" (
            echo !GAME_TO_UPDATE!=%DATE% %TIME%>> "%TEMP_FILE%"
            set "FOUND=true"
        ) else (
            echo %%a=%%b>> "%TEMP_FILE%"
        )
    )
)

if "%FOUND%"=="false" (
    echo !GAME_TO_UPDATE!=%DATE% %TIME%>> "%TEMP_FILE%"
)

if exist "%TEMP_FILE%" (
    copy /y "%TEMP_FILE%" "%RECENT_FILE%" >nul
    del "%TEMP_FILE%" >nul
) else (
    echo !GAME_TO_UPDATE!=%DATE% %TIME%> "%RECENT_FILE%"
)

goto :eof

:: =================== SAFE LAUNCH FUNCTION ===================
:SafeLaunch
:: Function to safely launch an application with error handling
setlocal
echo Launching: %*
if "%ERROR_RECOVERY%"=="true" (
    :: Try to run the command and capture any errors
    %* 2>"%TEMP%\launch_error.log"
    if errorlevel 1 (
        echo Error detected during launch ^(code: %errorlevel%^)
        echo Command: %* >> "%ERROR_LOG%"
        type "%TEMP%\launch_error.log" >> "%ERROR_LOG%"
        echo Error recorded to log file.
    ) else (
        echo Launch successful.
    )
) else (
    :: Run without error capturing if recovery is disabled
    %*
)
endlocal
goto :eof

:: =================== CACHE MANAGEMENT ===================
:CheckGameCacheStatus
setlocal
set "CACHE_VALID=false"
set "CACHE_TIMEOUT=86400"  :: 24 hours in seconds

:: Check if cache files exist
if not exist "%DOS_CACHE%" goto :CacheInvalid
if not exist "%GBA_CACHE%" goto :CacheInvalid
if not exist "%ISO_CACHE%" goto :CacheInvalid

:: Check cache age
for %%f in ("%DOS_CACHE%") do set "CACHE_TIME=%%~tf"

:: Convert cache time to seconds
for /f "tokens=1-5 delims=/ :., " %%a in ("!CACHE_TIME!") do (
    set /a "CACHE_SECONDS=((%%c*365 + %%b*31 + %%a) * 86400) + (%%d*3600 + %%e*60)"
)

:: Get current time in seconds
for /f "tokens=1-5 delims=/ :., " %%a in ("%DATE% %TIME%") do (
    set /a "CURRENT_SECONDS=((%%c*365 + %%b*31 + %%a) * 86400) + (%%d*3600 + %%e*60)"
)

:: Calculate elapsed time
set /a "ELAPSED_SECONDS=%CURRENT_SECONDS% - %CACHE_SECONDS%"

:: Check if cache is still valid
if %ELAPSED_SECONDS% lss %CACHE_TIMEOUT% (
    set "CACHE_VALID=true"
)

:CacheInvalid
:: Return cache validity to parent process
endlocal & set "CACHE_VALID=%CACHE_VALID%"
goto :eof