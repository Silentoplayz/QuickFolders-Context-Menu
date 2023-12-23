# Function to Write Log
function Write-Log {
    param ([string]$Message)
    Write-Host $Message
}

# Function to Add QuickFolders to Context Menu
function Add-QuickFoldersToContextMenu {
    try {
        $quickFoldersPath = "HKCU:\Software\Classes\Directory\Background\shell\QuickFolders"
        Remove-ExistingKey -Path $quickFoldersPath
        Create-RegistryKey -Path $quickFoldersPath -Properties @{
            "MUIVerb" = "QuickFolders"
            "SubCommands" = ""
        }

        Add-SubMenuItems -QuickFoldersPath $quickFoldersPath
        Write-Log "QuickFolders menu option added to the desktop context menu."
    } catch {
        Write-Log "Error adding QuickFolders to context menu: $_"
    }
}

# Function to Remove QuickFolders from Context Menu
function Remove-QuickFoldersFromContextMenu {
    try {
        $quickFoldersPath = "HKCU:\Software\Classes\Directory\Background\shell\QuickFolders"
        Remove-ExistingKey -Path $quickFoldersPath
        Write-Log "QuickFolders menu option removed from the desktop context menu."
    } catch {
        Write-Log "Error removing QuickFolders from context menu: $_"
    }
}

# Function to Remove Existing Registry Key
function Remove-ExistingKey {
    param ([string]$Path)
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse
    }
}

# Function to Create Registry Key
function Create-RegistryKey {
    param (
        [string]$Path,
        [hashtable]$Properties
    )
    New-Item -Path $Path -Force | Out-Null
    foreach ($key in $Properties.Keys) {
        Set-ItemProperty -Path $Path -Name $key -Value $Properties[$key]
    }
}

# Function to Add Sub-Menu Items
function Add-SubMenuItems {
    param ([string]$QuickFoldersPath)
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
    Get-ChildItem -Path $desktopPath -Directory | ForEach-Object {
        $subMenuPath = "$QuickFoldersPath\shell\$($_.Name)"
        Create-RegistryKey -Path $subMenuPath -Properties @{
            "MUIVerb" = $_.Name
        }
        Create-RegistryKey -Path "$subMenuPath\command" -Properties @{
            "(default)" = "explorer.exe `"$($_.FullName)`""
        }
    }
}

# Function to Prompt User for Action
function Prompt-UserAction {
    try {
        $action = Read-Host "Do you want to Add (A) or Remove (R) the QuickFolders option? (A/R)"
        switch ($action.ToUpper()) {
            "A" {
                $confirm = Read-Host "Are you sure you want to ADD QuickFolders to the context menu? (Y/N)"
                if ($confirm -eq 'Y') { Add-QuickFoldersToContextMenu }
            }
            "R" {
                $confirm = Read-Host "Are you sure you want to REMOVE QuickFolders from the context menu? (Y/N)"
                if ($confirm -eq 'Y') { Remove-QuickFoldersFromContextMenu }
            }
            default { Write-Log "Invalid selection. Please enter 'A' to Add or 'R' to Remove."; Prompt-UserAction }
        }
    } catch {
        Write-Log "An error occurred: $_"
    }
}

# Check for Administrative Privileges
function Check-AdminPrivileges {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "Please run this script as an Administrator."
        exit
    }
}

# Main Script Execution
Check-AdminPrivileges
Prompt-UserAction
