<#
    .SYNOPSIS
        Application Configuration - Disable Chrome Password Storage
    .DESCRIPTION
        This script disables the Chrome password manager using the registry and then clears existing passwords by removing the contents of `$ENV:\SystemDrive\Users\*\AppData\Local\Google\Chrome\User Data\*\Login Data`. By necessity this script will force-end any running Chrome processes.
    .EXAMPLE
        .\ChromePasswordManagerConfig.ps1 -RemoveExistingPasswords -DisablePasswordManager

        Disables the Chrome password manager and removes any existing passwords.
    .EXAMPLE
        .\ChromePasswordManagerConfig.ps1 -RemoveExistingPasswords

        Removes any existing passwords.
    .EXAMPLE
        .\ChromePasswordManagerConfig.ps1 -DisablePasswordManager

        Disables the Chrome password manager.
    .EXAMPLE
        .\ChromePasswordManagerConfig.ps1 -EnablePasswordManager

        Enables the Chrome password manager.        
    .NOTES
        2023-12-17: Initial version. Adapted/tested for Chrome by Ogre (NinjaOne Discord)
    .LINK
        Blog post: https://homotechsual.dev/2023/12/18/browser-password-manager-configuration/
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$RemoveExistingPasswords,
    [Parameter()]
    [switch]$DisablePasswordManager,
    [Parameter()]
    [switch]$EnablePasswordManager
)
# Utility Function: Registry.ShouldBe
## This function is used to ensure that a registry value exists and is set to a specific value.
function Registry.ShouldBe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Value,
        [Parameter(Mandatory)]
        [ValidateSet('String','ExpandString','Binary','DWord','MultiString','QWord')]
        [string]$Type
    )
    begin {
        # Make sure the registry path exists.
        if (!(Test-Path $Path)) {
            Write-Warning ("Registry path '$Path' does not exist. Creating.")
            New-Item -Path $Path -Force | Out-Null
        }
        # Make sure it's actually a registry path.
        if (!(Get-Item $Path).PSProvider.Name -eq 'Registry' -and !(Get-Item $Path).PSIsContainer) {
            throw "Path '$Path' is not a registry path."
        }
    }
    process {
        do {
            # Make sure the registry value exists.
            if (!(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)) {
                Write-Warning ("Registry value '$Name' in path '$Path' does not exist. Setting to '$Value'.")
                New-ItemProperty -Path $Path -Name $Name -Value $Value -Force | Out-Null
            }
            # Make sure the registry value is correct.
            if ((Get-ItemProperty -Path $Path -Name $Name).$Name -ne $Value) {
                Write-Warning ("Registry value '$Name' in path '$Path' is not correct. Setting to '$Value'.")
                Set-ItemProperty -Path $Path -Name $Name -Value $Value
            }
        } while ((Get-ItemProperty -Path $Path -Name $Name).$Name -ne $Value)
    }
}
# Disable the Chrome password manager.
if ($DisablePasswordManager) {
    # Disable the Chrome password manager.
    Write-Host "Disabling the Chrome password manager."
    Registry.ShouldBe -Path 'HKLM:\SOFTWARE\Policies\Google\Chrome' -Name 'PasswordManagerEnabled' -Value 0 -Type DWord
}
# Enable the Chrome password manager.
if ($EnablePasswordManager) {
    # Enable the Chrome password manager.
    Write-Host "Enabling the Chrome password manager."
    Registry.ShouldBe -Path 'HKLM:\SOFTWARE\Policies\Google\Chrome' -Name 'PasswordManagerEnabled' -Value 1 -Type DWord
}
# Remove existing passwords.
if ($RemoveExistingPasswords) {
    # Get the Chrome process(es).
    $ChromeProcesses = Get-Process -Name 'chrome' -ErrorAction SilentlyContinue
    # If there are any Chrome processes, kill them.
    if ($ChromeProcesses) {
        Write-Host "Killing Chrome processes."
        $ChromeProcesses | Stop-Process -Force
    }
    # Get the Chrome user data directories.
    $UserPath = Join-Path -Path $ENV:SystemDrive -ChildPath 'Users'
    $UserProfiles = Get-ChildItem -Path $UserPath -Directory -ErrorAction SilentlyContinue
    $ChromePasswordFiles = foreach ($UserProfile in $UserProfiles) {
        $ChromeProfilePath = Join-Path -Path $UserProfile.FullName -ChildPath 'AppData\Local\Google\Chrome\User Data\'
        $ChromeStateFile = Join-Path $ChromeProfilePath -ChildPath 'Local State'
        $ChromeState = Get-Content -Path $ChromeStateFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($ChromeState) {
            $ChromeProfiles = $ChromeState.profile.info_cache.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' } | Select-Object -ExpandProperty Name
            foreach ($ChromeProfile in $ChromeProfiles) {
                $ChromeProfilePath = Join-Path -Path $UserProfile.FullName -ChildPath "AppData\Local\Google\Chrome\User Data\$ChromeProfile"
                $ChromePasswordFile = Join-Path -Path $ChromeProfilePath -ChildPath 'Login Data'
                if (Test-Path -Path $ChromePasswordFile) {
                    $ChromePasswordFile
                } else {
                    Write-Warning ('User {0} profile {1} does not have a password file.' -f $UserProfile.Name, $ChromeProfile)
                }
            }
        }
    }
    # If there are any Chrome password files, remove the contents of the Login Data file.
    if ($ChromePasswordFiles) {
        Write-Host "Removing existing passwords."
        foreach ($ChromePasswordFile in $ChromePasswordFiles) {
            Write-Host "Removing existing passwords from $ChromePasswordFile"
            Remove-Item -Force -Path $ChromePasswordFile
        }
    }
}
