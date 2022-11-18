<#==============================================================
This script does the following:
1. Logs the script progress in users 'Documents\Install Log' folder.
2. Conveniently sets my user environment '$env:Project' to my default project folder.
3. Installs Windows Features.
4. Installs PS Modules.
5. Installs applications.
6. Installs default VS Code extensions.
7. Configures my default Task Schedules.

a) For customizations - find available Chocolatey NuGet packages from web: https://chocolatey.org/packages
b) Note: In my experience - the VS Code Extension part doesn't work until you reload the PowerShell,
   this is why I use Invoke-Command or Invoke-Expression on a new PS window instead
c) You're free to modify this script as you want and if you do find improvements, please file a bug or feature request
   as an issue at Github or notify me at gchi@recursion.no
d) Do not hesitate to contribute a bug fix or feature implementation by submitting a pull request, but keep in mind
   Commit with a summarized explanation about the change
==============================================================#>

#=============== START SCRIPT ===============#
# Initialize path parameters:
$logFilePath = $env:USERPROFILE + '\Documents\Install Log'
$vsCodePath = ($env:USERPROFILE + '\AppData\Local\Programs\Microsoft VS Code\'), 'C:\Program Files\Microsoft VS Code\', 'C:\Program Files (x86)\Microsoft VS Code\'
# Initialize Windows features, Powershell modules, WinGet packages and VSCode extensions:
$optionalFeatures = 'Microsoft-Windows-Subsystem-Linux', 'Microsoft-Hyper-V-All'
$modules = 'Az', 'posh-git', 'oh-my-posh', 'Microsoft.Graph', 'ExchangeOnlineManagement', 'MicrosoftTeams', 'Microsoft.Online.SharePoint.PowerShell', 'PnP.PowerShell'
$winGetPackages = 'Git.Git', 'GitHub.cli', '7zip.7zip', 'Microsoft.Teams', 'JanDeDobbeleer.OhMyPosh', 'SlackTechnologies.Slack', 'Microsoft.PowerToys', 'Postman.Postman', 'qBittorrent.qBittorrent', 'Balena.Etcher', 'Microsoft.VisualStudioCode', 'qBittorrent.qBittorrent', 'Postman.Postman', 'Docker.DockerDesktop', 'Microsoft.PowerToys', '9WZDNCRFJ3PS'<# Microsoft Remote Desktop #>
$extensions = 'vscode.powershell', 'ms-vscode.powershell', 'ms-vscode-remote.remote-wsl', 'ms-dotnettools.csharp', 'ms-vscode.cpptools', 'visualstudioexptteam.vscodeintellicode', 'ms-vscode.azure-account', 'ms-azuretools.vscode-logicapps', 'vscode.docker', 'vscode.yaml', 'ms-azuretools.vscode-docker', 'ms-toolsai.jupyter', 'ms-python.python', 'ecmel.vscode-html-css', 'felixfbecker.php-intellisense'
# Automatically add my own permanent Project environment variable, this can be replaced/customized as suited for you:
[Environment]::SetEnvironmentVariable("Projects", "$env:USERPROFILE\SynologyDrive\Projects", "User")
# Initialize script-logging during installation:
$logDate = Get-Date -Format ddMMyyy-HHmmss
if (!(Test-Path $logfilePath)) {
    New-Item $logFilePath -ItemType Directory
}
# Adding installation logs parameters:
Function Write-ClientInstallLog {
    param(
        [Parameter(Mandatory = $true)][String]$logmessage
    )
    Add-Content "$logFilePath\InstallReport - $logdate.log" "$(Get-Date -Format HH:mm:ss) - $logmessage" # Make sure folder exist
}
# Enables Windows Optional Features:
forEach ($feature in $optionalFeatures) {
    try {
        $logMessage = "Enabling Windows Feature $feature"
        Write-ClientInstallLog $logMessage
        Write-Host $logMessage
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
    }
    catch {
        $logMessage = "$feature was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        Write-Warning $logMessage
        Write-ClientInstallLog $logMessage
    }
}
# Installs necessary package-providers in beforehand, this is to avoid confirmation-prompts during the module installations:
Install-PackageProvider -Name "NuGet" -Confirm: $false -Force -EA SilentlyContinue
# Install PowerShell modules:
Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Get-Module | Update-Module -Confirm: $false -Force -EA SilentlyContinue
forEach ($module in $modules) {
    try {
        $logMessage = "Installing PSModule $module"
        Write-ClientInstallLog $logMessage
        Write-Host $logMessage
        Install-Module $module -Confirm: $false -AllowClobber -Force -EA SilentlyContinue
    }
    catch {
        $logMessage = "$module was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        Write-Warning $logMessage
        Write-ClientInstallLog $logMessage
    }
}
Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope Process
Update-Help -Confirm: $false -Force -EA SilentlyContinue

# Install WinGet and WinGet packages:
$hasPackageManager = Get-AppPackage -name "Microsoft.DesktopAppInstaller"
if ($hasPackageManager) {
    $logMessage = "WinGet already installed, continuing with packages"
    Write-Host $logMessage
    Write-ClientInstallLog $logMessage
    foreach ($winGetPackage in $winGetPackages) {
        try {
            $logMessage = "Installing $winGetPackage"
            Write-ClientInstallLog $logMessage
            Write-Host $logMessage
            winget install --id $winGetPackage -e -h --source winget --accept-package-agreements --accept-source-agreements
        }
        catch {
            $logMessage = "$winGetPackage was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
            Write-Warning $logMessage
            Write-ClientInstallLog $logMessage
        }
    }
}
else {
    try {
        $logMessage = "WinGet not found, trying to fetch and install from WinGet's GitHub repository..."
        Write-Host $logMessage
        Write-ClientInstallLog $logMessage
        Add-AppxPackage -Path "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $releases = Invoke-RestMethod -uri $releases_url
        $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith("msixbundle") } | Select-Object -First 1
        Add-AppxPackage -Path $latestRelease.browser_download_url
        foreach ($winGetPackage in $winGetPackages) {
            try {
                $logMessage = "Installing $winGetPackage"
                Write-ClientInstallLog $logMessage
                Write-Host $logMessage
                winget install --id $winGetPackage -e -h --source winget --accept-package-agreements --accept-source-agreements
            }
            catch {
                $logMessage = "$winGetPackage was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
                Write-Warning $logMessage
                Write-ClientInstallLog $logMessage
            }
        }
    }
    catch {
        if ($Error.Exception -like "*404*") {
            $logMessage = "The URL to fetch install-script for WinGet was not found or has been changed, please visit https://learn.microsoft.com/en-us/windows/package-manager/winget `
            to replace the URL or contact gchi@recursion.no for troubleshooting"
            Write-Warning $logMessage
            Write-ClientInstallLog $logMessage
        }
        if ($Error.Exception -notlike "*404*") {
            $logMessage = "WinGet failed to install caused by the following Error:`n$Error[0].Exception.GetType().FullName"
            Write-Warning $logMessage
            Write-ClientInstallLog $logMessage
        }
    }
}

# Updates the PowerShell & Cmd variables that VSCode will use to install extensions:
foreach ($level in "Machine", "User") {
    try {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            # For Path variables, append the new values, if they're not already in there
            if ($_.Name -match 'Path$') { 
                $_.Value = ($((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select-Object -unique) -join ';'
            }
            $_
        } | Set-Content -Path { "Env:$($_.Name)" }
    }
    catch {
        if ($Error.Exception -like "*Get-Content : Cannot find path*") {
            <# Do nothing and skip to next #>
        }
        else {
            throw
        }
    }
    
}

# Install Visual Studio Code Extensions:
foreach ($path in $vsCodePath) {
    if (Test-Path -Path $path) {
        Write-Output "VS Code found in $path"
        forEach ($extension in $Extensions) {
            try {
                $logMessage = "Installing VSCode extension $extension"
                Write-ClientInstallLog $logMessage
                Write-Host $logMessage
                Code --install-extension $extension --force
            }
            catch {
                $logMessage = "VSCode extension $extension was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
                Write-Warning $logMessage
                Write-ClientInstallLog $logmessage
            }
        }
    }
    else {
        $logMessage = "VS Code was not found in $path"
        Write-ClientInstallLog $logMessage
    }
}

<#try {
    $logMessage = "Trying to invoke VS Code Extension script"
    Write-Host $logMessage
    Write-ClientInstallLog $logMessage
    Invoke-Expression -EA SilentlyContinue $vsExtCmd #Alternative: Invoke-Command ScriptBlock{<script here>}
}
catch {
    $logMessage = "Failed to invoke VS Code Extension script - skipped process.`n$Error[0].Exception.GetType().FullName"
    Write-Warning $logMessage
    Write-ClientInstallLog $logMessage
}

# Specify the settings for scheduled tasks:
$RegisterScheduledTask = @{
    TaskName = "Windows SpotLight Image Fetcher",
    Trigger = New-ScheduledTaskTrigger -AtStartup,
    User = "Users",
    Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\Users\gchi\SynologyDrive\Projects\Powershell\CopyWindowsSpotlightPictures.ps1",
    RunLevel = Highest
}
# Create Scheduled tasks

try {
    Write-ClientInstallLog "Configuring Scheduled tasks $task"
    Write-Warning "Configuring Scheduled tasks $task"
    Register-ScheduledTask $RegisterScheduledTask –Force
    }
catch {
    Write-Warning "Failed to configure scheduled task, skipping to next scheduled task"
    Write-ClientInstallLog "Failed to configure scheduled task caused by the following Error:`n$Error[0].Exception.GetType().FullName"
}
#>
#=============== END SCRIPT ===============#