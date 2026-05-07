@echo off
set "ROOT=%~dp0"
set "OPENCLAW_STATE_DIR=%ROOT%openclaw-home"
set "OPENCLAW_CONFIG_PATH=%ROOT%openclaw-home\openclaw.json"
set "PATH=%ROOT%runtime\git\cmd;%ROOT%runtime\node;%ROOT%runtime\npm-global;%PATH%"
set "OPENCLAW_CMD=%ROOT%runtime\npm-global\openclaw.cmd"
if not exist "%OPENCLAW_CMD%" for %%I in (openclaw.cmd) do set "OPENCLAW_CMD=%%~$PATH:I"
if not exist "%OPENCLAW_CMD%" (
  echo OpenClaw CLI has not been installed yet.
  pause
  exit /b 1
)
call "%OPENCLAW_CMD%" gateway run --port 18789 --bind loopback --auth token --force --verbose
