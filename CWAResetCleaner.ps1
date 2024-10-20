<#
    Script Name: Citrix Workspace App Reset Script
    Author: Jesse Boehm
    Version: 4.1
    Description: 
        This script resets the Citrix Workspace App by stopping related processes, clearing cached files, 
        deleting user-specific registry keys, and removing Citrix stores from the registry. 
        It mimics the "Reset Workspace" option available in the GUI.
        Added ability to delete stores from registry and reset Citrix Workspace App.
#>

# Arrays to store messages
$infoMessages = New-Object System.Collections.Generic.List[System.String]
$errorMessages = New-Object System.Collections.Generic.List[System.String]
$warningMessages = New-Object System.Collections.Generic.List[System.String]

# Function to log errors and store them for later output
function Log-Error {
    param (
        [string]$Message
    )
    $errorMessages.Add("[ERROR] $Message")
}

# Function to log warnings and store them for later output
function Log-Warning {
    param (
        [string]$Message
    )
    $warningMessages.Add("[WARNING] $Message")
}

# Function to log informational messages and store them for later output
function Log-Info {
    param (
        [string]$Message
    )
    $infoMessages.Add("[INFO] $Message")
}

# Define the Citrix processes to kill
$citrixProcesses = @("SelfService", "Receiver", "redirector", "wfcrun32", "concentr.exe")

# Kill the processes
foreach ($process in $citrixProcesses) {
    try {
        $proc = Get-Process -Name $process -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Stop-Process -Force -ErrorAction Stop
            Log-Info "Process '$process' terminated successfully."
        } else {
            Log-Warning "Process '$process' not found."
        }
    } catch {
        Log-Error "Failed to terminate process '$process'."
    }
}

# Define the folder paths to clear (user-specific)
$citrixPaths = @(
    "$env:LOCALAPPDATA\Citrix",
    "$env:APPDATA\Citrix",
    "$env:APPDATA\ICAClient",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\Content.IE5",  # Citrix uses this IE cache location
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\Virtualized",   # Another Citrix-specific cache location
    "$env:LOCALAPPDATA\Temp\Citrix"
)

# Delete files and folders (user-level)
foreach ($path in $citrixPaths) {
    try {
        if (Test-Path $path) {
            Log-Info "Folder '$path' exists. Proceeding with file and folder deletion."

            # Remove all files in the directory
            Get-ChildItem -Path $path -Recurse -Force -ErrorAction Stop | Remove-Item -Force -Recurse -ErrorAction Stop
            Log-Info "Files in '$path' deleted successfully."

            # Remove the folder itself
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Log-Info "Folder '$path' deleted successfully."
        } else {
            Log-Warning "Folder '$path' does not exist."
        }
    } catch {
        Log-Error "Failed to delete folder or files in '$path'."
    }
}

# Define user-level registry keys to delete (HKCU)
$registryPaths = @(
    "HKCU\Software\Citrix\Receiver",
    "HKCU\Software\Citrix\Dazzle",
    "HKCU\Software\Citrix\ICA Client",
    "HKCU\Software\Citrix\PNAgent",
    "HKCU\Software\Citrix\SelfService"
)

# Define registry keys for Citrix stores
$citrixStorePaths = @(
    "HKCU\Software\Citrix\Store",
    "HKCU\Software\Citrix\StoreWeb"
)

# Delete user-level registry keys
foreach ($regPath in $registryPaths) {
    try {
        if (Test-Path "Registry::$regPath") {
            Remove-Item -Path "Registry::$regPath" -Recurse -Force -ErrorAction Stop
            Log-Info "Deleted registry key: $regPath"
        } else {
            Log-Warning "Registry key not found: $regPath"
        }
    } catch {
        Log-Error "Failed to delete registry key: $regPath - $_"
    }
}

# Delete Citrix store registry keys
foreach ($storePath in $citrixStorePaths) {
    try {
        if (Test-Path "Registry::$storePath") {
            Remove-Item -Path "Registry::$storePath" -Recurse -Force -ErrorAction Stop
            Log-Info "Deleted Citrix store registry key: $storePath"
        } else {
            Log-Warning "Citrix store registry key not found: $storePath"
        }
    } catch {
        Log-Error "Failed to delete Citrix store registry key: $storePath - $_"
    }
}

# Output all stored messages, grouped by type

# Output Info messages (Green text)
if ($infoMessages.Count -gt 0) {
    Write-Host "`n--- Informational Messages ---" -ForegroundColor Green
    foreach ($message in $infoMessages) {
        Write-Host $message -ForegroundColor Green
    }
}

# Output Warning messages (Light blue text)
if ($warningMessages.Count -gt 0) {
    Write-Host "`n--- Warning Messages ---" -ForegroundColor Cyan
    foreach ($message in $warningMessages) {
        Write-Host $message -ForegroundColor Cyan
    }
}

# Output Error messages (Red text)
if ($errorMessages.Count -gt 0) {
    Write-Host "`n--- Error Messages ---" -ForegroundColor Red
    foreach ($message in $errorMessages) {
        Write-Host $message -ForegroundColor Red
    }
}
