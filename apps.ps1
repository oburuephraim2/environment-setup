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
        [string]$PackageId,
        [string]$DisplayName
    )
    $installed = winget list --id $PackageId | Select-String $PackageId
    if ($installed) {
        Write-Host "$DisplayName already installed. Skipping..."
    } else {
        Write-Host "Installing $DisplayName..."
        winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements -e
    }
}

# Define available packages
$packages = @(
    @{ Id = "Google.Chrome"; Name = "Google Chrome" },
    @{ Id = "Mozilla.Firefox"; Name = "Mozilla Firefox" },
    @{ Id = "Adobe.Acrobat.Reader.64-bit"; Name = "Adobe Acrobat Reader" },
    @{ Id = "AnyDeskSoftwareGmbH.AnyDesk"; Name = "AnyDesk" },
    @{ Id = "Microsoft.VisualStudioCode.Insiders"; Name = "Visual Studio Code (Insiders)" },
    @{ Id = "Python.Python.3"; Name = "Python 3" },
    @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js LTS" },
    @{ Id = "Git.Git"; Name = "Git" },
    @{ Id = "GitHub.GitHubDesktop"; Name = "GitHub Desktop" },
    @{ Id = "Cloudflare.cloudflared"; Name = "Cloudflared" }
)

# Show menu
Write-Host "Select the packages you want to install (comma-separated numbers):"
for ($i = 0; $i -lt $packages.Count; $i++) {
    Write-Host "$($i+1). $($packages[$i].Name)"
}
Write-Host "A. Install ALL packages"

# Read user input
$userChoice = Read-Host "Enter your choices (e.g. 1,3,5 or A for all)"

if ($userChoice -eq "A" -or $userChoice -eq "a") {
    Write-Host "Installing all packages..."
    foreach ($pkg in $packages) {
        Install-Package -PackageId $pkg.Id -DisplayName $pkg.Name
    }
} else {
    $choices = $userChoice -split "," | ForEach-Object { $_.Trim() }
    foreach ($choice in $choices) {
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $packages.Count) {
            $pkg = $packages[[int]$choice - 1]
            Install-Package -PackageId $pkg.Id -DisplayName $pkg.Name
        } else {
            Write-Warning "Invalid choice: $choice"
        }
    }
}

Write-Host "Installation process complete!"
