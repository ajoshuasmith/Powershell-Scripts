<#
.SYNOPSIS
    Ensures one or more DNS suffixes exist in the global search list.
.DESCRIPTION
    Reads the current suffix search list via Get-DnsClientGlobalSetting, adds any
    suffixes that are missing (preserving the original order), and writes the updated
    list back with Set-DnsClientGlobalSetting. Supports specifying multiple suffixes and
    honors -WhatIf / -Confirm.
.PARAMETER Suffixes
    One or more DNS suffix strings (e.g. contoso.com) to guarantee in the search list.
.EXAMPLE
    .\Add-DnsSuffixSearchList.ps1 -Suffixes 'domain.com'
.EXAMPLE
    .\Add-DnsSuffixSearchList.ps1 -Suffixes 'corp.contoso.com', 'lab.contoso.com'
.NOTES
    Requires administrative privileges to modify DNS client global settings.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Suffixes
)

$currentSettings = Get-DnsClientGlobalSetting
$currentList = @()
if ($currentSettings.SuffixSearchList) {
    $currentList = [string[]]$currentSettings.SuffixSearchList
}

$normalizedSuffixes = $Suffixes | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.Trim() }
if (-not $normalizedSuffixes) {
    Write-Warning 'No valid suffix strings were provided.'
    return
}

$newSuffixes = @()
foreach ($suffix in $normalizedSuffixes) {
    if ($currentList -notcontains $suffix -and $newSuffixes -notcontains $suffix) {
        $newSuffixes += $suffix
    }
}

if (-not $newSuffixes) {
    Write-Host 'All requested suffixes already exist in the search list. No changes made.'
    return
}

$updatedList = $currentList + $newSuffixes

if ($PSCmdlet.ShouldProcess("DNS Suffix Search List", "Add: $($newSuffixes -join ', ')") ) {
    try {
        Set-DnsClientGlobalSetting -SuffixSearchList $updatedList -ErrorAction Stop
        Write-Host ("Updated suffix search list: {0}" -f ($updatedList -join ', '))
    } catch {
        Write-Error ("Failed to update DNS suffix list: {0}" -f $_)
        exit 1
    }
}
