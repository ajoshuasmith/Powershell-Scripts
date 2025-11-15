<#
.SYNOPSIS
    Resets passwords for specified local accounts in a reusable, automation-friendly way.
.DESCRIPTION
    Looks up local user accounts by name and sets a new password for each. You can supply
    the password as
    a secure string, as plain text, or interactively. Supports -WhatIf/-Confirm.
.PARAMETER UserNames
    One or more local account names whose passwords should be updated. This parameter is
    required so the script never touches unexpected accounts.
.PARAMETER SecurePassword
    SecureString value that represents the new password. Use when calling from another
    script or secret store where the password is already protected.
.PARAMETER PasswordPlainText
    Convenience parameter that accepts a plain-text password and converts it internally
    to a SecureString. Prefer SecurePassword for production use.
.EXAMPLE
    Set-LocalDefaultPasswords.ps1 -UserNames 'Helpdesk', 'Technician' -PasswordPlainText 'Temp!123710!'
.EXAMPLE
    $password = Read-Host -Prompt 'Enter password' -AsSecureString
    .\\Set-LocalDefaultPasswords.ps1 -SecurePassword $password
.NOTES
    Author: Joshua Smith
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
[Parameter(Mandatory = $true)]
[ValidateNotNullOrEmpty()]
[string[]]$UserNames,

[Parameter()]
[System.Security.SecureString]$SecurePassword,

    [Parameter()]
    [string]$PasswordPlainText
)

function Get-SecurePassword {
    param (
        [System.Security.SecureString]$SecureString,
        [string]$PlainText
    )

    if ($SecureString) {
        return $SecureString
    }

    if ($PlainText) {
        return ConvertTo-SecureString -String $PlainText -AsPlainText -Force
    }

    Write-Verbose 'Prompting for password because none was supplied.'
    $prompted = Read-Host -Prompt 'Enter the new password' -AsSecureString
    if (-not $prompted) {
        throw 'A password is required to continue.'
    }
    return $prompted
}

try {
    $resolvedPassword = Get-SecurePassword -SecureString $SecurePassword -PlainText $PasswordPlainText
} catch {
    Write-Error $_
    exit 1
}

$targetUsers = Get-LocalUser | Where-Object { $UserNames -contains $_.Name }

if (-not $targetUsers) {
    Write-Warning ("No local accounts found matching: {0}" -f ($UserNames -join ', '))
    exit 0
}

foreach ($user in $targetUsers) {
    if ($PSCmdlet.ShouldProcess($user.Name, 'Set local password')) {
        try {
            Set-LocalUser -Name $user.Name -Password $resolvedPassword -ErrorAction Stop
            Write-Host ("Password changed for user: {0}" -f $user.Name)
        } catch {
            Write-Error ("Failed to set password for {0}: {1}" -f $user.Name, $_)
        }
    }
}
