# Function to Write Log with Verbose Option
function Write-Log {
    param (
        [string]$Message,
        [switch]$Verbose
    )
    $prefix = if ($Verbose) { "VERBOSE: " } else { "" }
    Write-Host "${prefix}$Message"
}

# Function to Manage QuickFolders in Context Menu
function Manage-QuickFoldersContextMenu {
    param (
        [string]$Action,
        [switch]$Verbose
    )
    $quickFoldersPath = "HKCU:\Software\Classes\Directory\Background\shell\QuickFolders"
    try {
        switch ($Action) {
            "Add" {
                Remove-ExistingKey -Path $quickFoldersPath -Verbose:$Verbose
                Create-RegistryKey -Path $quickFoldersPath -Properties @{
                    "MUIVerb" = "QuickFolders"
                    "SubCommands" = ""
                } -Verbose:$Verbose
                Add-SubMenuItems -QuickFoldersPath $quickFoldersPath -Verbose:$Verbose
                Write-Log "QuickFolders menu option added to the desktop context menu." -Verbose:$Verbose
            }
            "Remove" {
                Remove-ExistingKey -Path $quickFoldersPath -Verbose:$Verbose
                Write-Log "QuickFolders menu option removed from the desktop context menu." -Verbose:$Verbose
            }
        }
    } catch {
        Write-Log "Error managing QuickFolders in context menu: $_" -Verbose:$Verbose
    }
}

# Function to Remove Existing Registry Key
function Remove-ExistingKey {
    param (
        [string]$Path,
        [switch]$Verbose
    )
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse
        Write-Log "Removed registry key: $Path" -Verbose:$Verbose
    }
}

# Function to Create Registry Key
function Create-RegistryKey {
    param (
        [string]$Path,
        [hashtable]$Properties,
        [switch]$Verbose
    )
    New-Item -Path $Path -Force | Out-Null
    Write-Log "Created registry key: $Path" -Verbose:$Verbose
    foreach ($key in $Properties.Keys) {
        Set-ItemProperty -Path $Path -Name $key -Value $Properties[$key]
        Write-Log "Set property '$key' to '$($Properties[$key])' on '$Path'" -Verbose:$Verbose
    }
}

# Function to Add Sub-Menu Items
function Add-SubMenuItems {
    param (
        [string]$QuickFoldersPath,
        [switch]$Verbose
    )
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
    Get-ChildItem -Path $desktopPath -Directory | ForEach-Object {
        $subMenuPath = "$QuickFoldersPath\shell\$($_.Name)"
        Create-RegistryKey -Path $subMenuPath -Properties @{
            "MUIVerb" = $_.Name
        } -Verbose:$Verbose
        Create-RegistryKey -Path "$subMenuPath\command" -Properties @{
            "(default)" = "explorer.exe `"$($_.FullName)`""
        } -Verbose:$Verbose
    }
}

# Function to Prompt User for Action
function Prompt-UserAction {
    try {
        $action = Read-Host "Do you want to Add (A) or Remove (R) the QuickFolders option? (A/R)"
        switch ($action.ToUpper()) {
            "A" {
                $confirm = Read-Host "Are you sure you want to ADD QuickFolders to the context menu? (Y/N)"
                if ($confirm -eq 'Y') { Manage-QuickFoldersContextMenu -Action "Add" -Verbose }
            }
            "R" {
                $confirm = Read-Host "Are you sure you want to REMOVE QuickFolders from the context menu? (Y/N)"
                if ($confirm -eq 'Y') { Manage-QuickFoldersContextMenu -Action "Remove" -Verbose }
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
