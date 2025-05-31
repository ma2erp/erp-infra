$imageName = "frappe_app_container"
$imageTag = "latest"
$containerName = "my-frappe-instance"

$volumes = @(
    "frappe_sites_data",
    "frappe_assets_data",
    "frappe_logs_data",
    "frappe_mysql_data"
)

# --- 1. Build the Docker Image ---

# Check if the image is already built
$existingImage = docker images --filter "reference=$($imageName):$($imageTag)" --format "{{.Repository}}:{{.Tag}}"
if ($existingImage) {
    Write-Host "Docker image '$($imageName):$($imageTag)' already exists. Skipping build."
} else {
    Write-Host "Building Docker image '$($imageName):$($imageTag)'..."
    docker build -t "$($imageName):$($imageTag)" .

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker image build failed. Exiting."
        exit 1
    }
    Write-Host "Docker image built successfully."
}

# --- 2. Create Named Volumes (if they don't exist) ---
Write-Host "Ensuring Docker volumes exist..."
foreach ($volume in $volumes) {
    Write-Host "  Checking volume: $volume"
    # The 'docker volume create' command is idempotent, so it won't re-create if exists
    docker volume create $volume
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create volume '$volume'. Exiting."
        exit 1
    }
}

Write-Host "All required Docker volumes are in place."

# --- 3. Stop and Remove existing container if it's running/exists ---

Write-Host "Checking for existing container '$containerName'..."
$existingContainer = docker ps -a --filter "name=$containerName" --format "{{.ID}}"
if ($existingContainer) {
    Write-Host "  Existing container '$containerName' found. Stopping and removing..."
    docker stop $containerName
    docker rm $containerName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to stop/remove existing container. Exiting."
        exit 1
    }
    Write-Host "  Existing container removed."
} else {
    Write-Host "  No existing container '$containerName' found."
}

# --- 4. Run the Docker Container ---

Write-Host "Running Docker container '$containerName'..."

$volumeMountArgs = ""
$volumeMountArgs += "-v frappe_sites_data:/home/frappeuser/erpnext-bench/sites "
$volumeMountArgs += "-v frappe_assets_data:/home/frappeuser/erpnext-bench/sites/assets "
$volumeMountArgs += "-v frappe_logs_data:/home/frappeuser/erpnext-bench/logs "
$volumeMountArgs += "-v frappe_mysql_data:/var/lib/mysql "

# The full run command
$runCommand = "docker run -it -p 8000:8000 -p 9000:9000 $volumeMountArgs $($imageName):$($imageTag) $containerName"
Write-Host "Executing: $runCommand"
Invoke-Expression $runCommand

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker container failed to start. Check logs for details."
    exit 1
}

Write-Host "Frappe container '$containerName' started successfully!"
Write-Host "Access Frappe ERPNext at http://localhost:8000"
Write-Host "You can stop the container by pressing Ctrl+C in this window."