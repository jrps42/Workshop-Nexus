$projectRoot = Split-Path -Parent $PSScriptRoot

Set-Location $projectRoot

$venvActivate = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"

if (-not (Test-Path $venvActivate)) {
    Write-Error "Python virtual environment not found at $venvActivate"
    exit 1
}

& $venvActivate

Write-Host "Starting Workshop Nexus backend..."
python -m uvicorn backend.app.main:app --reload