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

function Get-PackageSelection {
    while ($true) {
        $userChoice = Read-Host "Enter your choices (e.g. 1,3,5 or A for all)"

        if ([string]::IsNullOrWhiteSpace($userChoice)) {
            Write-Warning "No selection entered. Please choose one or more package numbers, or 'A' to install all."
            continue
        }

        if ($userChoice -ieq 'A') {
            return 1..$packages.Count
        }

        $choices = $userChoice -split '[,\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

        $valid = @()
        $invalid = @()

        foreach ($ch in $choices) {
            if ($ch -match '^\d+$' -and [int]$ch -ge 1 -and [int]$ch -le $packages.Count) {
                $valid += [int]$ch
            } else {
                $invalid += $ch
            }
        }

        if ($invalid.Count -gt 0) {
            Write-Warning "Invalid choice(s): $($invalid -join ', '). Please enter only numbers between 1 and $($packages.Count), or 'A'."
            continue
        }

        if ($valid.Count -gt 0) {
            return $valid | Sort-Object -Unique
        }

        Write-Warning "No valid package numbers selected. Please try again."
    }
}

$selection = Get-PackageSelection

foreach ($index in $selection) {
    $pkg = $packages[$index - 1]
    Install-Package -PackageId $pkg.Id -DisplayName $pkg.Name
}

Write-Host "Installation process complete!"
