$projectRoot = Split-Path -Parent $PSScriptRoot
$backendScript = Join-Path $PSScriptRoot "start_backend.ps1"
$frontendScript = Join-Path $PSScriptRoot "start_frontend.ps1"

Write-Host "Launching Workshop Nexus..."

Start-Process `
    -FilePath "powershell.exe" `
    -WorkingDirectory $projectRoot `
    -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $backendScript
    )

Start-Sleep -Seconds 3

Start-Process `
    -FilePath "powershell.exe" `
    -WorkingDirectory $projectRoot `
    -ArgumentList @(
        "-NoExit",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        $frontendScript
    )

Write-Host "Backend and frontend processes started."