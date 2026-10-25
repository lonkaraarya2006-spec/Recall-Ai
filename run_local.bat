@echo off
setlocal
cd /d "%~dp0"

REM Find a Python command without requiring the Windows "py" launcher.
set "PYTHON_CMD="
where python >nul 2>&1
if not errorlevel 1 set "PYTHON_CMD=python"
if not defined PYTHON_CMD (
  where python3 >nul 2>&1
  if not errorlevel 1 set "PYTHON_CMD=python3"
)
if not defined PYTHON_CMD (
  echo Python was not found. Install Python 3.11 or 3.12 from https://www.python.org/downloads/
  echo During installation, select "Add Python to PATH", then reopen this file.
  pause
  exit /b 1
)

if not exist .venv\Scripts\python.exe (
  echo Creating Python virtual environment using %PYTHON_CMD%...
  %PYTHON_CMD% -m venv .venv
  if errorlevel 1 goto failed
)

if not exist .venv\packages-ready (
  echo Installing Recall AI dependencies. This may take several minutes on first run...
  .venv\Scripts\python.exe -m pip install --upgrade pip
  if errorlevel 1 goto failed
  .venv\Scripts\python.exe -m pip install -r backend\requirements.txt
  if errorlevel 1 goto failed
  echo ready>.venv\packages-ready
)

if not exist .env copy .env.example .env >nul
echo.
echo Starting Recall AI at http://127.0.0.1:8000
echo API documentation: http://127.0.0.1:8000/docs
echo Keep this window open. Press Ctrl+C to stop the server.
.venv\Scripts\python.exe -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
pause
goto :eof

:failed
echo.
echo Setup failed. Check the error above and confirm internet access for package installation.
pause
exit /b 1
