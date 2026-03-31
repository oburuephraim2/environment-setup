# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ensure winget is installed
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "Winget is not installed. Please install 'App Installer' from the Microsoft Store."
    exit
}

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

    Write-Host "`n>>> Checking $DisplayName ($PackageId)..." -ForegroundColor Cyan

    # Check if already installed - Using --source winget to ensure a clean lookup
    $check = winget list --id "$PackageId" --exact --source winget 2>$null
    
    if ($check -match $PackageId) {
        Write-Host "$DisplayName is already installed. Skipping..." -ForegroundColor Yellow
    } else {
        Write-Host "Installing $DisplayName (Waiting for completion - no timeout)..."
        try {
            # Added --source winget here to fix "No package found" errors
            $args = @(
                "install", 
                "--id", $PackageId, 
                "--silent", 
                "--disable-interactivity", 
                "--force", 
                "--accept-package-agreements", 
                "--accept-source-agreements", 
                "--source", "winget",
                "-e"
            )
            
            $process = Start-Process -FilePath "winget" -ArgumentList $args -NoNewWindow -PassThru
            
            # Wait Indefinitely: This fixes the 5-minute timeout issue for large apps like Adobe
            $process.WaitForExit()
            
            # Check if installed after attempt
            $checkAfter = winget list --id "$PackageId" --exact --source winget 2>$null
            if ($checkAfter -match $PackageId) {
                Write-Host "SUCCESS: $DisplayName installed." -ForegroundColor Green
            } else {
                Write-Warning "FAILED: $DisplayName could not be installed."
            }
        }
        catch {
            Write-Warning "ERROR: Failed to launch winget for $DisplayName. Details: $_"
        }
    }
}

# Define available packages with corrected IDs
$packages = @(
    @{ Id = "Google.Chrome"; Name = "Google Chrome" },
    @{ Id = "Adobe.Acrobat.Reader.64-bit"; Name = "Adobe Acrobat Reader (64-bit)" },
    @{ Id = "AnyDesk.AnyDesk"; Name = "AnyDesk" }, # Corrected ID (previously AnyDeskSoftwareGmbH.AnyDesk)
    @{ Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" },
    @{ Id = "Python.Python.3"; Name = "Python 3" },
    @{ Id = "OpenJS.NodeJS.LTS"; Name = "Node.js LTS" },
    @{ Id = "Git.Git"; Name = "Git" },
    @{ Id = "GitHub.GitHubDesktop"; Name = "GitHub Desktop" },
    @{ Id = "Cloudflare.cloudflared"; Name = "Cloudflared" },
    @{ Id = "Mozilla.Firefox"; Name = "Mozilla Firefox" }
)

# Show menu
Write-Host "`n--- Software Installation Menu ---" -ForegroundColor Blue
for ($i = 0; $i -lt $packages.Count; $i++) {
    Write-Host "$($i+1). $($packages[$i].Name)"
}
Write-Host "A. Install ALL packages"
Write-Host "----------------------------------`n"

function Get-PackageSelection {
    while ($true) {
        $userChoice = Read-Host "Enter your choices (e.g. 1,3,5 or A for all)"

        if ([string]::IsNullOrWhiteSpace($userChoice)) {
            Write-Warning "No selection entered."
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
            Write-Warning "Invalid choice(s): $($invalid -join ', ')."
            continue
        }

        if ($valid.Count -gt 0) {
            return $valid | Sort-Object -Unique
        }

        Write-Warning "No valid numbers selected."
    }
}

$selection = Get-PackageSelection

foreach ($index in $selection) {
    $pkg = $packages[$index - 1]
    Install-Package -PackageId $pkg.Id -DisplayName $pkg.Name
}

Write-Host "`nInstallation process complete!" -ForegroundColor Green
