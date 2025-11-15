<#
.SYNOPSIS
    Cycles all healthy display adapters by disabling and re-enabling them.
.DESCRIPTION
    Retrieves display-class PnP devices whose status is OK, disables each adapter,
    waits briefly, then re-enables it. This can clear transient GPU driver issues
    without a reboot. Requires administrative privileges and the PnpDevice module
    (available on Windows 10+). Honors -WhatIf/-Confirm.
.PARAMETER DelaySeconds
    Number of seconds to wait between disable and enable operations. Defaults to 3.
.EXAMPLE
    .\Reset-DisplayAdapters.ps1
.EXAMPLE
    .\Reset-DisplayAdapters.ps1 -DelaySeconds 5 -Verbose
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter()]
    [ValidateRange(0, 30)]
    [int]$DelaySeconds = 3
)

$displayAdapters = Get-PnpDevice -Class Display | Where-Object { $_.Status -eq 'OK' }

if (-not $displayAdapters) {
    Write-Warning 'No display adapters in an OK state were found. Nothing to do.'
    return
}

foreach ($adapter in $displayAdapters) {
    Write-Verbose ("Processing adapter: {0}" -f $adapter.FriendlyName)

    if ($PSCmdlet.ShouldProcess($adapter.FriendlyName, 'Disable display adapter')) {
        Write-Host ("Disabling display adapter: {0}" -f $adapter.FriendlyName)
        Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false
    }

    if ($DelaySeconds -gt 0) {
        Start-Sleep -Seconds $DelaySeconds
    }

    if ($PSCmdlet.ShouldProcess($adapter.FriendlyName, 'Enable display adapter')) {
        Write-Host ("Re-enabling display adapter: {0}" -f $adapter.FriendlyName)
        Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false
    }
}

Write-Host 'Display adapter reset complete.'
