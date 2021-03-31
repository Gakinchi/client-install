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
b) Note: In my experience - the VS Code Extension commands doesn't work until you reload the PowerShell,
   this is why I use Invoke-Command or Invoke-Expression on a new PS window instead.
c) You're free to modify this script and if you do find improvements, please git push it or notify me at gchi@recursion.no
==============================================================#>

#=============== START SCRIPT ===============#
# Initialize path parameters:
$vsCodePath = ($env:USERPROFILE + '\AppData\Local\Programs\Microsoft VS Code\'), 'C:\Program Files\Microsoft VS Code\', 'C:\Program Files (x86)\Microsoft VS Code\'
$chocoPath = $env:ProgramData + '\Chocolatey'
$logFilePath = $env:USERPROFILE + '\Documents\Install Log'
# Initialize features, modules, packages and extensions:
$optionalFeatures = 'Microsoft-Windows-Subsystem-Linux', 'Microsoft-Hyper-V-All'
$modules = 'Az', 'posh-git', 'oh-my-posh', 'Microsoft.Graph', 'ExchangeOnlineManagement', 'MicrosoftTeams', 'Microsoft.Online.SharePoint.PowerShell', 'PnP.PowerShell'
$packages = 'git', 'gh', '7zip', 'microsoft-teams', 'microsoft-windows-terminal', 'cascadiacode', 'cascadiacodepl', 'oh-my-posh', 'poshgit', 'slack', 'powertoys', 'postman', 'qbittorrent', '1password', 'etcher', 'au', 'epicgameslauncher', 'steam-client', 'docker-cli', 'vscode'
$extensions = 'vscode.powershell', 'ms-vscode.powershell', 'ms-vscode-remote.remote-wsl', 'ms-dotnettools.csharp', 'ms-vscode.cpptools', 'visualstudioexptteam.vscodeintellicode', 'ms-vscode.azure-account', 'ms-azuretools.vscode-logicapps', 'vscode.docker', 'vscode.yaml', 'ms-azuretools.vscode-docker', 'ms-toolsai.jupyter', 'ms-python.python', 'ecmel.vscode-html-css', 'felixfbecker.php-intellisense'
# Automatically add my own permanent Project environment variable, this can be replaced/customized as suited for you:
[Environment]::SetEnvironmentVariable("Projects", "$env:USERPROFILE\SynologyDrive\Projects", "User")
# Initialize script-log:
$logDate = Get-Date -Format ddMMyyy-HHmmss
if (!(Test-Path $logfilePath)) {
    New-Item $logFilePath -ItemType Directory
}
Function Write-ClientInstallLog {
    param(
        [Parameter(Mandatory = $true)][String]$logmessage
    )
    Add-Content "$logFilePath\chocoReport - $logdate.txt" "$(Get-Date -Format HH:mm:ss) - $logmessage" # Make sure folder exist
}
# Enables Windows Optional Features:
ForEach ($feature in $optionalFeatures) {
    try {
        Write-ClientInstallLog "Enabling Windows Feature $feature"
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
    }
    catch {
        Write-Warning "$feature was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        Write-ClientInstallLog "$feature was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
    }
}
# Install PowerShell modules:
Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Get-Module | Update-Module -Confirm: $false -Force -EA SilentlyContinue
ForEach ($module in $modules) {
    try {
        Write-ClientInstallLog "Installing PSModule $module"
        Write-Warning "Installing PSModule $module"
        Install-Module $module -Confirm: $false -AllowClobber -Force -EA SilentlyContinue
    }
    catch {
        Write-Warning "$module was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        Write-ClientInstallLog "$module was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
    }
}
Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope Process
Update-Help -Confirm: $false -Force -EA SilentlyContinue
# Install Chocolatey and packages:
If (Test-Path -Path $chocoPath) {
    Write-Warning "Chocolatey already installed, continuing with packages"
    Write-ClientInstallLog "Chocolatey already installed, continuing with packages"
    foreach ($package in $packages) {
        try {
            Write-ClientInstallLog "Installing $package"
            choco install $package -y
        }
        catch {
            Write-Warning "$package was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
            Write-ClientInstallLog "$package was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        }
    }
}
else {
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force -EA Stop; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        ForEach ($package in $Packages) {
            try {
                
                Write-ClientInstallLog "Installing $package"
                choco install $package -y
            }
            catch {
                Write-Warning "$package was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
                Write-ClientInstallLog "$package was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
            }
        }
    }
    catch {
        # Use cmdline '$theError | Format-List * -Force' to see all sub-properties of a thrown error-code... and then`
        # create an if function to make a custom error message handling - e.g.: 'if ($theError.Exception -like "*404*")'
        if ($Error.Exception -like "*404*") {
            Write-Warning "The URL to fetch install-script for Chocolatey was not found or has been changed, please visit https://chocolatey.org/install `
            to replace the URL or contact gakin@imara.ai for troubleshooting"
            Write-ClientInstallLog "The URL to fetch install-script for Chocolatey was not found or has been changed, please visit https://chocolatey.org/install `
            to replace the URL or contact gakin@imara.ai for troubleshooting"
        }
        if ($Error.Exception -notlike "*404*") {
            Write-Warning "Chocolatey failed to install - Skipping package installs"
            Write-ClientInstallLog "Chocolatey failed to install caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        }
    }
}
# Install Visual Studio Code Extensions:
$vsExtCmd =
'cmd /c start powershell -NoExit -Command {
    foreach ($path in $vsCodePath) {
        if (Test-Path -Path $path) {
            Write-Output "VS Code found in $path"
            forEach ($extension in $extensions) {
                try {
                    Write-ClientInstallLog "Installing extension $extension"
                    Write-Warning "Installing extension $extension"
                    Code --install-extension $extension --Force
                }
                catch {
                    Write-Warning "$extension was not installed - extension skipped."
                    Write-ClientInstallLog "$extension was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
                }
            }
        }
        else {
            Write-Warning "VS Code was not found in $path"
            Write-ClientInstallLog "VS Code was not found in $path caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        }
    }
}'
try {
    Write-ClientInstallLog "Trying to invoke VS Code Extension script"
    Write-Warning "Trying to invoke VS Code Extension script"
    Invoke-Expression $vsExtCmd # Alternative Invoke-Command ScriptBlock{<script here>} - if you need the intellisense.
}
catch {
    Write-Warning "Failed to invoke VS Code Extension script - skipped process."
    Write-ClientInstallLog "Failed to invoke VS Code Extension script caused by the following Error:`n$Error[0].Exception.GetType().FullName"
}
# Specify the settings for scheduled tasks:
$schedName = "Windows SpotLight Image Fetcher"
$startupTrigger = New-ScheduledTaskTrigger -AtStartup
$schedUser = "Users"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\Users\gchi\SynologyDrive\Projects\Powershell\CopyWindowsSpotlightPictures.ps1"
# Create Scheduled tasks
try {
    Write-ClientInstallLog "Configuring Scheduled tasks $task"
    Write-Warning "Configuring Scheduled tasks $task"
    Register-ScheduledTask -TaskName $schedName -Trigger $startupTrigger -User $schedUser -Action $Action -RunLevel Highest –Force
    }
catch {
    Write-Warning "Failed to configure scheduled task, skipping to next scheduled task"
    Write-ClientInstallLog "Failed to configure scheduled task caused by the following Error:`n$Error[0].Exception.GetType().FullName"
}
#=============== END SCRIPT ===============#