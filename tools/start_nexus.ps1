$projectRoot = Split-Path -Parent $PSScriptRoot
$frontendPath = Join-Path $projectRoot "frontend"

if (-not (Test-Path $frontendPath)) {
    Write-Error "Flutter frontend not found at $frontendPath"
    exit 1
}

Set-Location $frontendPath

Write-Host "Starting Workshop Nexus frontend..."
flutter run -d windows