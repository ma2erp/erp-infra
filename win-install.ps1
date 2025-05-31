$repoPath = "erp-infra"

# Install git
$ErrorActionPreference = "Stop"
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if (-not $gitInstalled) {
    Write-Host "Git is not installed. Installing Git..."
    Start-Process -FilePath "powershell" -ArgumentList "-Command", "winget install --id Git.Git -e --source winget" -Wait
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install Git. Exiting."
        exit 1
    }
    Write-Host "Git installed successfully."
}
else {
    Write-Host "Git is already installed."
}

# Install Docker
$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue

if (-not $dockerInstalled) {
    Write-Host "Docker is not installed. Installing Docker..."
    Start-Process -FilePath "powershell" -ArgumentList "-Command", "winget install --id Docker.DockerDesktop -e --source winget" -Wait
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install Docker. Exiting."
        exit 1
    }
    Write-Host "Docker installed successfully."
}
else {
    Write-Host "Docker is already installed."
}

if (-Not (Test-Path -Path $repoPath)) { 
    Write-Host "Cloning the repository $repoPath..."
    git clone https://github.com/ma2erp/erp-infra.git

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone the repository. Exiting."
        exit 1
    }
    Write-Host "Repository cloned successfully."
}
else {
    Write-Host "Repository $repoPath already exists. Skipping clone."
}

$currentLocation = Get-Location
Set-Location -Path $repoPath

Write-Host "Current directory changed to: $(Get-Location)"

try {

$dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (-Not (Test-Path -Path $dockerDesktopPath)) {
    Write-Error "Docker Desktop executable not found at $dockerDesktopPath. Please ensure Docker Desktop is installed."
    exit 1
} else {
    Write-Host "Starting Docker Desktop..."
    if (-not (Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue)) {
        Write-Host "Docker Desktop is not running. Starting it now... Rerun this script after Docker Desktop is fully started."
        Start-Process -FilePath $dockerDesktopPath -PassThru -ErrorAction SilentlyContinue | Out-Null
        exit 1
    } else {
        Write-Host "Docker Desktop is already running."
    }
}

$scriptPath = ".\erpnext-windows.ps1"
if (Test-Path -Path $scriptPath) {
    Write-Host "Running the script: $scriptPath"
    . $scriptPath
} else {
    Write-Error "Script file not found: $scriptPath. Exiting."
    exit 1
}

} finally {
    Set-Location -Path $currentLocation
    Write-Host "Returning to the original directory: $currentLocation"
}