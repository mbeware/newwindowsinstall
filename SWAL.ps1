# install winget
# Install-Module -Name Microsoft.WinGet.Client
# install chrome
# winget install -e --id Google.Chrome
# set it as default browser

# Allow script 
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser


# Define a function to check if a program is installed
function Is-Installed($ProgramName) {
    $app = Get-AppxPackage -Name $ProgramName -ErrorAction SilentlyContinue
    return $app -ne $null
}

# Function to install Winget manually if not present
function Install-Winget {
    Write-Host "Checking for Winget..."
    $wingetPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    
    if (-Not (Test-Path $wingetPath)) {
        Write-Host "Winget is not installed. Attempting to install..."
        $msiUrl = "https://aka.ms/getwinget"
        $installerPath = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"

        Invoke-WebRequest -Uri $msiUrl -OutFile $installerPath
        Add-AppxPackage -Path $installerPath
    	Write-Host "Checking if installation worked..."
    	$wingetPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
	if (-Not (Test-Path $wingetPath)) {
            Write-Host "Winget installation failed."
	    exit(0)
	} else {
            Write-Host "Succes! Winget is installed."
	}
        
    } else {
        Write-Host "Winget is already installed."
    }
}

# Function to install an application using Winget
function Install-UsingWinget($appName, $wingetId) {
    Write-Host "Checking for $appName..."
    if (-Not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Winget is missing. Installing..."
        Install-Winget
    }

    $installed = winget list --id $wingetId --exact | Select-String $wingetId
    if (-Not $installed) {
        Write-Host "Installing $appName..."
        Start-Process "winget" -ArgumentList "install --id=$wingetId --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait
    } else {
        Write-Host "$appName is already installed."
    }
}

# Set Chrome as the default browser 
function Set-Chrome-As-Default {
    Write-Host "Setting Chrome as the default browser..."
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice' -Name ProgId -Value 'ChromeHTML'
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' -Name ProgId -Value 'ChromeHTML'


    #    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    
    #    if (Test-Path $chromePath) {
    #        Start-Process -FilePath $chromePath -ArgumentList "--make-default-browser" -NoNewWindow -Wait
    #    } else {
    #        Write-Host "Chrome installation not found!"
    #    }
}

# Ensure file extensions are always shown
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

# Set default view to "Details" (Reset folder view settings)
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams\Defaults" -Force -ErrorAction SilentlyContinue
# Hide the search box from the taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0


# Hide News and Interests from the taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Value 2
# Hide the Cortana button from the taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCortanaButton" -Value 0

$edgeLnk = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk"

# Check if the Edge shortcut exists and remove it
if (Test-Path $edgeLnk) {
    Remove-Item $edgeLnk -Force
}

# Install Winget if missing
Install-Winget

# Install Google Chrome
Install-UsingWinget "Google Chrome" "Google.Chrome"

# Install VLC Media Player
Install-UsingWinget "VLC Media Player" "VideoLAN.VLC"



Set-Chrome-As-Default


$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$shortcutPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Google Chrome.lnk"

# Check if Chrome is installed
if (Test-Path $chromePath) {
    # Create a new shortcut object
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $chromePath
    $Shortcut.Save()

    Write-Host "Google Chrome has been pinned to the taskbar."
} else {
    Write-Host "Google Chrome is not installed in the default location."
}



# Set the Auto Time Zone Updater service to start automatically
Set-Service -Name "tzautoupdate" -StartupType Automatic

# Start the service
Start-Service -Name "tzautoupdate" -ErrorAction SilentlyContinue

# Enable "Set Time Zone Automatically" in the registry
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\tzautoupdate" -Name "Start" -Value 3

# Allow Windows to access location for time zone updates
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Allow"

Write-Host "Automatic timezone setting has been enabled."


# Restart Explorer for changes to take effect
Stop-Process -Name explorer -Force
Start-Process explorer
Write-Host "Installation process completed!"
