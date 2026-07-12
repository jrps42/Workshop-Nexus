$projectRoot = Split-Path -Parent $PSScriptRoot

Set-Location $projectRoot

$venvPython = Join-Path $projectRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $venvPython)) {
    Write-Error "Python virtual environment not found at $venvPython"
    exit 1
}

Write-Host "Starting Workshop Nexus backend..."

& $venvPython -m uvicorn backend.app.main:app --reload