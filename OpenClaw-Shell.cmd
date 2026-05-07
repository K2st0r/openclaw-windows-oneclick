@echo off
set "ROOT=%~dp0"
set "OPENCLAW_STATE_DIR=%ROOT%openclaw-home"
set "OPENCLAW_CONFIG_PATH=%ROOT%openclaw-home\openclaw.json"
set "PATH=%ROOT%runtime\git\cmd;%ROOT%runtime\node;%ROOT%runtime\npm-global;%PATH%"
if exist "%ROOT%openclaw-home\.env" (
  for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ROOT%openclaw-home\.env") do (
    if not "%%A"=="" set "%%A=%%~B"
  )
)
set "OPENCLAW_CMD=%ROOT%runtime\npm-global\openclaw.cmd"
if not exist "%OPENCLAW_CMD%" for %%I in (openclaw.cmd) do set "OPENCLAW_CMD=%%~$PATH:I"
if not exist "%OPENCLAW_CMD%" (
  echo OpenClaw CLI has not been installed yet.
  pause
  exit /b 1
)
title OpenClaw Local Shell
cmd /k
