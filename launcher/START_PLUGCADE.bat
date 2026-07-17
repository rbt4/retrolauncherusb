@echo off
setlocal
cd /d "%~dp0"
if exist "%SystemRoot%\System32\mshta.exe" (
  start "Plugcade" "%SystemRoot%\System32\mshta.exe" "%~dp0Plugcade.hta"
  exit /b 0
)
if exist "%SystemRoot%\SysWOW64\mshta.exe" (
  start "Plugcade" "%SystemRoot%\SysWOW64\mshta.exe" "%~dp0Plugcade.hta"
  exit /b 0
)
echo Plugcade could not start the graphical launcher.
echo Starting the lightweight fallback instead...
pause
call "%~dp0PLUGCADE-LITE.bat"
