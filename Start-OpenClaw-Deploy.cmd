@echo off
set "ROOT=%~dp0"
if exist "%ROOT%launcher-debug.log" del /f /q "%ROOT%launcher-debug.log" >nul 2>nul
echo Launching OpenClaw deployer v2026.05.06.10
powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -File "%ROOT%OpenClaw-OneClick-Deploy.ps1"
