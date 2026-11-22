@echo off
setlocal
set "ROOT=%~dp0"

python -c "import sys; assert sys.version_info[0] >= 3" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    python "%ROOT%start.py" %*
    exit /b %ERRORLEVEL%
)

where node >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    node "%ROOT%start.mjs" %*
    exit /b %ERRORLEVEL%
)

echo [NORTE BOUND] Neither Python 3 nor Node.js was found in PATH.
exit /b 1
