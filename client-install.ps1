# For customizations - find available Chocolatey NuGet packages from web: https://chocolatey.org/packages
# gchi@recursion.no

# //START SCRIPT//

# Initialize path parameters:
$vsCodePath = ($env:USERPROFILE+'\AppData\Local\Programs\Microsoft VS Code\'),'C:\Program Files\Microsoft VS Code\','C:\Program Files (x86)\Microsoft VS Code\'
$chocoPath = $env:ProgramData + '\Chocolatey'
$logFilePath = $env:USERPROFILE + '\Documents\Install Log'

$scheduledTasks = @{
    SpotLightImageFetcher = $env:USERPROFILE + '\SynologyDrive\Projects\Powershell\CopyWindowsSpotlightPictures.ps1'
}
# Initialize a variable with a list of Windows Optional Features to Enable:
$optionalFeatures = 'Microsoft-Windows-Subsystem-Linux', 'Microsoft-Hyper-V-All'
# Initialize a variable with a list of Powershell modules to install:
$modules = 'Az', 'posh-git', 'oh-my-posh', 'Microsoft.Graph', 'ExchangeOnlineManagement', 'MicrosoftTeams', 'Microsoft.Online.SharePoint.PowerShell', 'PnP.PowerShell'
# Initialize a variable with a list of NuGet packages to install:
$packages = 'git', 'gh', '7zip', 'microsoft-teams', 'microsoft-windows-terminal', 'cascadiacode', 'cascadiacodepl', 'oh-my-posh', 'poshgit', 'slack', 'powertoys', 'postman', 'qbittorrent', '1password', 'etcher', 'au', 'epicgameslauncher', 'steam-client', 'docker-cli', 'vscode'
# Initialize a variable with a list of VS Code extensions to install:
$extensions = 'vscode.powershell', 'ms-vscode.powershell', 'ms-vscode-remote.remote-wsl', 'ms-dotnettools.csharp', 'ms-vscode.cpptools', 'visualstudioexptteam.vscodeintellicode', 'ms-vscode.azure-account', 'ms-azuretools.vscode-logicapps', 'vscode.docker', 'vscode.yaml', 'ms-azuretools.vscode-docker', 'ms-toolsai.jupyter', 'ms-python.python', 'ecmel.vscode-html-css', 'felixfbecker.php-intellisense'

# Automatically add my own permanent Project environment variable, this can be replaced/customized as suited for you:
[Environment]::SetEnvironmentVariable("Projects", "$env:USERPROFILE\SynologyDrive\Projects", "User")

# UNDER DEV: INITIALIZE TIMEOUT TIMER:
Function ResetTimer {
    $script:startTime = [DateTime]::Now
}
Function IsTimeout([TimeSpan]$timeout) {
    return ([DateTime]::Now - $startTime) -ge $timeout
}
# END OF DEV TIMEOUT TIMER

# Initialize log function:
$logDate = Get-Date -Format ddMMyyy-HHmmss
if (!(Test-Path $logfilePath)) {
    New-Item $logFilePath -ItemType Directory
}
Function Write-SPImportLog {
    param(
        [Parameter(Mandatory = $true)][String]$logmessage
    )
    Add-Content "$logFilePath\chocoReport - $logdate.txt" "$(Get-Date -Format HH:mm:ss) - $logmessage" # Make sure folder exist
}
# End log function
# Enables Windows Optional Features:
ForEach ($feature in $optionalFeatures) {
    try {
        Write-SPImportLog "Enabling Windows Feature $feature"
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
    }
    catch {
        Write-Warning "$feature was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        Write-SPImportLog "$feature was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
    }
}
# Install PowerShell modules:
Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Get-Module | Update-Module -Confirm: $false -Force -EA SilentlyContinue
ForEach ($module in $modules) {
    try {
        Write-SPImportLog "Installing PSModule $module"
        Install-Module $module -Confirm: $false -AllowClobber -Force -EA SilentlyContinue
    }
    catch {
        Write-Warning "$module was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        Write-SPImportLog "$module was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
    }
}
Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope Process
Update-Help -Confirm: $false -Force -EA SilentlyContinue
# Install Chocolatey and all packages:
If (Test-Path -Path $chocoPath) {
    Write-Warning "Chocolatey already installed, continuing with packages"
    Write-SPImportLog "Chocolatey already installed, continuing with packages"
    foreach ($package in $packages) {
        try {
            Write-SPImportLog "Installing $package"
            choco install $package -y
        }
        catch {
            Write-Warning "$package was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
            Write-SPImportLog "$package was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        }
    }
}
else {
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force -EA Stop; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        ForEach ($package in $Packages) {
            try {
                Write-SPImportLog "Installing $package"
                choco install $package -y
            }
            catch {
                Write-Warning "$package was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
                Write-SPImportLog "$package was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
            }
        }
    }
    catch {
        # Use cmdline '$theError | Format-List * -Force' to see all sub-properties of a thrown error-code... and then`
        # create an if function to make a custom error message handling - e.g.: 'if ($theError.Exception -like "*404*")'
        if ($Error.Exception -like "*404*") {
            Write-Warning "The URL to fetch installscript for Chocolatey was not found or has been changed, please visit https://chocolatey.org/install `
            to replace the URL or contact gakin@imara.ai for troubleshooting"
            Write-SPImportLog "The URL to fetch installscript for Chocolatey was not found or has been changed, please visit https://chocolatey.org/install `
            to replace the URL or contact gakin@imara.ai for troubleshooting"
        }
    }
}
# Install Visual Studio Code Extensions
foreach ($path in $vsCodePath) {
    if (Test-Path -Path $path) {
        Write-Output $path
        try {
            forEach ($extension in $extensions) {
                Write-SPImportLog "Installing extension $extension"
                Write-Warning "Installing extension $extension"
                Code --install-extension $extension --Force
            }
        }
        catch {
            Write-Warning "help1"
            Write-SPImportLog "$extension was not installed caused by the following Error:`n$Error[0].Exception.GetType().FullName"
        }
    }
    else {
        Write-Warning "help2"
        Write-SPImportLog "VS Code was not found in $path because of the following Error:`n\n$Error[0].Exception.GetType().FullName"
    }
}

# Create Scheduled tasks
foreach ($task in $scheduledTasks) {
    $Trigger = New-ScheduledTaskTrigger -AtStartup # Specify the trigger settings
    $User = "Users" # Specify the account to run the script
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\Users\gchi\SynologyDrive\Projects\Powershell\CopyWindowsSpotlightPictures.ps1" # Specify what program to run and with its parameters
    Register-ScheduledTask -TaskName $task -Trigger $Trigger -User $User -Action $Action -RunLevel Highest –Force # Specify the name of the task
}

# //END SCRIPT//