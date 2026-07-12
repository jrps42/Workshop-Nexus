@echo off
setlocal

set "PROJECT_ROOT=%~dp0"
set "PYTHON=%PROJECT_ROOT%.venv\Scripts\python.exe"
set "FRONTEND=%PROJECT_ROOT%frontend"

if not exist "%PYTHON%" (
    echo.
    echo ERROR: Python virtual environment not found.
    echo Expected:
    echo %PYTHON%
    echo.
    pause
    exit /b 1
)

if not exist "%FRONTEND%\pubspec.yaml" (
    echo.
    echo ERROR: Flutter frontend not found.
    echo Expected:
    echo %FRONTEND%
    echo.
    pause
    exit /b 1
)

echo ========================================
echo Starting Workshop Nexus
echo ========================================
echo.

start "Nexus Backend" cmd /k ^
    "cd /d "%PROJECT_ROOT%" && "%PYTHON%" -m uvicorn backend.app.main:app --reload"

echo Waiting for backend startup...
timeout /t 3 /nobreak >nul

start "Nexus Frontend" cmd /k ^
    "cd /d "%FRONTEND%" && flutter run -d windows"

echo.
echo Workshop Nexus launch commands started.
echo Backend:  http://127.0.0.1:8000
echo API docs: http://127.0.0.1:8000/docs
echo.
exit /b 0