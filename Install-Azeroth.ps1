$ErrorActionPreference = "Stop"

Write-Host "=== AzerothCore Playerbots Installer ==="

# Load config
$manifest = Get-Content ".\manifest.json" | ConvertFrom-Json

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverDir = Join-Path $root "server"

# -------------------------
# 1. Preconditions
# -------------------------
Write-Host "Checking prerequisites..."

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is not installed."
}

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker is not installed."
}

if (!(Test-Path $manifest.client_path)) {
    throw "WoW client not found at: $($manifest.client_path)"
}

# -------------------------
# 2. Start DB
# -------------------------
Write-Host "Starting MariaDB..."
docker compose up -d

Start-Sleep -Seconds 10

# -------------------------
# 3. Clone Core
# -------------------------
Write-Host "Cloning AzerothCore Playerbots fork..."

if (!(Test-Path "$serverDir\core")) {
    git clone $manifest.core.repo "$serverDir\core"
}

# -------------------------
# 4. Modules
# -------------------------
Write-Host "Installing modules..."

$modulesPath = "$serverDir\core\modules"

if (!(Test-Path $modulesPath)) {
    New-Item -ItemType Directory -Path $modulesPath | Out-Null
}

foreach ($mod in $manifest.modules.PSObject.Properties) {
    $target = "$modulesPath\$($mod.Name)"

    if (!(Test-Path $target)) {
        git clone $mod.Value $target
    }
}

# -------------------------
# 5. Build
# -------------------------
Write-Host "Building core (this will take a while)..."

cd "$serverDir\core"

mkdir build -Force | Out-Null
cd build

cmake .. -DTOOLS=1 -DSCRIPTS=dynamic -DMODULES=static

cmake --build . --config Release

# -------------------------
# 6. Copy DB configs
# -------------------------
Write-Host "Preparing configs..."

cd $root

# -------------------------
# 7. Client extraction reminder
# -------------------------
Write-Host ""
Write-Host "IMPORTANT: Run map extraction tools from:"
Write-Host $manifest.client_path
Write-Host ""

# -------------------------
# 8. Done
# -------------------------
Write-Host "INSTALL COMPLETE"
Write-Host "Use Play-WoW.bat to start server"
