$projectRoot = Split-Path -Parent $PSScriptRoot
$backendPython = Join-Path $projectRoot ".venv\Scripts\python.exe"
$frontendPath = Join-Path $projectRoot "frontend"
$healthUrl = "http://127.0.0.1:8000/health"
$maxAttempts = 20

Write-Host ""
Write-Host "========================================"
Write-Host "Starting Workshop Nexus"
Write-Host "========================================"
Write-Host ""

if (-not (Test-Path $backendPython)) {
    Write-Error "Python virtual environment not found at: $backendPython"
    exit 1
}

if (-not (Test-Path (Join-Path $frontendPath "pubspec.yaml"))) {
    Write-Error "Flutter frontend not found at: $frontendPath"
    exit 1
}

function Test-BackendHealth {
    try {
        $response = Invoke-WebRequest `
            -Uri $healthUrl `
            -UseBasicParsing `
            -TimeoutSec 2

        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

if (Test-BackendHealth) {
    Write-Host "Backend is already running."
}
else {
    Write-Host "Starting backend..."

    Start-Process `
        -FilePath "powershell.exe" `
        -WorkingDirectory $projectRoot `
        -ArgumentList @(
            "-NoExit",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            "& `"$backendPython`" -m uvicorn backend.app.main:app --reload"
        )

    Write-Host "Waiting for backend health check..."

    $backendReady = $false

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        Start-Sleep -Seconds 1

        if (Test-BackendHealth) {
            $backendReady = $true
            break
        }

        Write-Host "Backend not ready yet... attempt $attempt of $maxAttempts"
    }

    if (-not $backendReady) {
        Write-Error "Backend did not become healthy. Check the backend window for errors."
        exit 1
    }
}

Write-Host "Backend is ready."
Write-Host "Starting Flutter frontend..."

Start-Process `
    -FilePath "powershell.exe" `
    -WorkingDirectory $frontendPath `
    -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        "flutter run -d windows"
    )

Write-Host ""
Write-Host "Workshop Nexus launch started."
Write-Host "Backend:  http://127.0.0.1:8000"
Write-Host "API docs: http://127.0.0.1:8000/docs"
Write-Host "Health:   $healthUrl"
Write-Host ""