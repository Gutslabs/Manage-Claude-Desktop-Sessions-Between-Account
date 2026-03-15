@echo off
setlocal

set "SCRIPT=%~dp0sync-claude-local-sessions.ps1"

if not exist "%SCRIPT%" (
    echo Sync script not found:
    echo %SCRIPT%
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

echo.
if errorlevel 1 (
    echo Sync failed.
) else (
    echo Sync finished. If Claude was open, restart it to reload sessions.
)

pause
