# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator."
    exit
}

# Enable TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Function to install packages via winget only if not already installed
function Install-Package {
    param (
        [string]$PackageId
    )
    $installed = winget list --id $PackageId | Select-String $PackageId
    if ($installed) {
        Write-Host "$PackageId already installed. Skipping..."
    } else {
        Write-Host "Installing $PackageId..."
        winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements -e
    }
}

# Install core development tools
Install-Package "Microsoft.VisualStudioCode.Insiders"
Install-Package "Python.Python.3"
Install-Package "OpenJS.NodeJS.LTS"
Install-Package "Git.Git"
Install-Package "GitHub.GitHubDesktop"
Install-Package "Cloudflare.cloudflared"
Install-Package "Google.Chrome"

# Create standard project directory
$projectPath = "$env:USERPROFILE\Projects"
if (-not (Test-Path $projectPath)) {
    New-Item -ItemType Directory -Path $projectPath
    Write-Host "Created project directory at $projectPath"
} else {
    Write-Host "Project directory already exists at $projectPath"
}

# Create Environment subfolder inside Projects
$envPath = "$projectPath\Environment"
if (-not (Test-Path $envPath)) {
    New-Item -ItemType Directory -Path $envPath
    Write-Host "Created environment directory at $envPath"
} else {
    Write-Host "Environment directory already exists at $envPath"
}

# Create Backup folder inside Environment
$backupPath = "$envPath\Backup"
if (-not (Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath
    Write-Host "Created backup directory at $backupPath"
}

# Create or reuse Python virtual environment inside Environment
$venvPath = "$envPath\venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "Creating Python virtual environment..."
    python -m venv $venvPath
    Write-Host "Virtual environment created at $venvPath"
} else {
    Write-Host "Virtual environment already exists at $venvPath"
}

# Function to update requirements.txt whenever packages change
function Update-Requirements {
    $activate = "$venvPath\Scripts\activate.ps1"
    if (Test-Path $activate) {
        Write-Host "Activating virtual environment..."
        & $activate
        Write-Host "Exporting requirements.txt..."
        pip freeze | Out-File "$envPath\requirements.txt"
        Write-Host "requirements.txt updated at $envPath"
    } else {
        Write-Warning "Virtual environment not found. Skipping requirements export."
    }
}

# Function to restore environment from requirements.txt on a new PC
function Restore-Requirements {
    $reqFile = "$envPath\requirements.txt"
    $activate = "$venvPath\Scripts\activate.ps1"
    if (Test-Path $reqFile -and Test-Path $activate) {
        Write-Host "requirements.txt found. Restoring packages..."
        & $activate
        pip install -r $reqFile
        Write-Host "Packages restored from requirements.txt"
    } else {
        Write-Host "No requirements.txt found. Skipping restore."
    }
}

# Backup configs (requirements, cloudflared, VS Code settings)
function Backup-Configs {
    Write-Host "Backing up configs..."
    if (Test-Path "$envPath\requirements.txt") {
        Copy-Item "$envPath\requirements.txt" -Destination "$backupPath\requirements.txt" -Force
    }
    if (Test-Path "$env:USERPROFILE\.cloudflared") {
        Copy-Item "$env:USERPROFILE\.cloudflared" -Destination "$backupPath\cloudflared" -Recurse -Force
    }
    if (Test-Path "$env:APPDATA\Code\User\settings.json") {
        Copy-Item "$env:APPDATA\Code\User\settings.json" -Destination "$backupPath\VSCode-settings.json" -Force
    }
    Write-Host "Configs backed up to $backupPath"
}

# Detect if this is a new PC (no requirements.txt yet)
if (-not (Test-Path "$envPath\requirements.txt")) {
    Write-Host "New environment detected. Creating fresh requirements.txt..."
    Update-Requirements
} else {
    Write-Host "Existing requirements.txt found. Attempting restore..."
    Restore-Requirements
}

# Always back up configs at the end
Backup-Configs

Write-Host "Developer environment setup complete!"
