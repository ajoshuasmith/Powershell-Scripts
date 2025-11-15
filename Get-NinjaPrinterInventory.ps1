<#
.SYNOPSIS
    Captures installed printers for both system and logged-on user contexts and uploads an HTML table to NinjaOne.
.DESCRIPTION
    Enumerates printers via Get-Printer from the system context and, when a user session is active, invokes the
    same enumeration in the user context using the RunAsUser module. Results are merged (deduplicated by name,
    port, and driver), converted to an HTML table, and written to a Ninja custom field using Ninja-Property-Set-Piped.
.PARAMETER PropertyName
    NinjaOne custom field (WYSIWYG) name to receive the HTML output. Defaults to 'printers'.
.PARAMETER ExcludePattern
    Regex used to skip standard virtual printers (OneNote, PDF, etc.). Provide an empty string to include all printers.
.EXAMPLE
    .\Get-NinjaPrinterInventory.ps1 -PropertyName 'printers'
.EXAMPLE
    .\Get-NinjaPrinterInventory.ps1 -PropertyName 'OfficePrinters' -ExcludePattern ''
.NOTES
    Requires administrative privileges. Installs RunAsUser module version 2.4.0 if missing.
#>
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PropertyName = 'printers',

    [Parameter()]
    [string]$ExcludePattern = 'Microsoft|Fax|OneNote|Adobe|Agency|PDF|Dentrix|WebEx'
)

Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

function Convert-ToHtmlTable {
    param (
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Objects
    )

    $objectsArray = @($Objects)
    if (-not $objectsArray) { return '<p>No printers found.</p>' }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<table><thead><tr>')
    $objectsArray[0].PSObject.Properties.Name | ForEach-Object { [void]$sb.Append("<th>$_</th>") }
    [void]$sb.Append('</tr></thead><tbody>')

    foreach ($obj in $objectsArray) {
        [void]$sb.Append('<tr>')
        foreach ($prop in $obj.PSObject.Properties) {
            $value = [System.Web.HttpUtility]::HtmlEncode([string]$prop.Value)
            [void]$sb.Append("<td>$value</td>")
        }
        [void]$sb.Append('</tr>')
    }

    [void]$sb.Append('</tbody></table>')
    return $sb.ToString()
}

function Ensure-RunAsUserModule {
    try { Import-Module RunAsUser -ErrorAction Stop | Out-Null; return }
    catch { }

    try {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue | Out-Null
        Import-Module PowerShellGet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        Get-PackageProvider -Name NuGet -ForceBootstrap -ErrorAction SilentlyContinue | Out-Null
        Install-Module RunAsUser -RequiredVersion '2.4.0' -Force -Scope AllUsers -ErrorAction Stop | Out-Null
        Import-Module RunAsUser -RequiredVersion '2.4.0' -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning ("Unable to install/import RunAsUser module: {0}" -f $_)
        throw
    }
}

function Get-LoggedOnUserName {
    $user = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName
    if ([string]::IsNullOrWhiteSpace($user)) { return $null }
    $domainSeparator = $user.LastIndexOf('\\')
    if ($domainSeparator -ge 0) { return $user.Substring($domainSeparator + 1) }
    return $user
}

function Get-PrinterInventory {
    param (
        [Parameter(Mandatory)]
        [string]$Context,
        [Parameter()]
        [string]$ExcludePattern
    )

    $printers = Get-Printer | Select-Object Name, PortName, DriverName
    if ($ExcludePattern) {
        $printers = $printers | Where-Object { $_.Name -notmatch $ExcludePattern }
    }

    $list = [System.Collections.Generic.List[object]]::new()
    foreach ($printer in $printers) {
        $ip = $null
        if ($printer.PortName -match 'WSD') {
            $locInfo = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\DAFWSDProvider\*" -ErrorAction SilentlyContinue |
                Where-Object { $_.FriendlyName -and $_.FriendlyName.Replace('(', '').Replace(')', '') -match [Regex]::Escape($printer.Name) } |
                Select-Object -ExpandProperty LocationInformation -First 1
            if ($locInfo) {
                $ipMatch = [regex]::Matches($locInfo, '\d{1,3}(\.\d{1,3}){3}')
                if ($ipMatch.Count -gt 0) { $ip = $ipMatch[0].Value }
            }
        }

        $list.Add([pscustomobject]@{
                Name       = $printer.Name
                PortName   = $printer.PortName
                DriverName = $printer.DriverName
                IP         = $ip
                Context    = $Context
        })
    }
    return $list
}

$tempFile = Join-Path -Path $env:TEMP -ChildPath ("ninja_printers_{0}.json" -f ([guid]::NewGuid().ToString('N')))
$loggedOnUser = Get-LoggedOnUserName

if ($loggedOnUser) {
    try {
        Ensure-RunAsUserModule
        $scriptBlock = {
            param($excludePattern, $outputPath)
            function Get-PrinterInventoryInternal {
                param($ctx, $pattern)
                $printers = Get-Printer | Select-Object Name, PortName, DriverName
                if ($pattern) { $printers = $printers | Where-Object { $_.Name -notmatch $pattern } }
                $list = [System.Collections.Generic.List[object]]::new()
                foreach ($printer in $printers) {
                    $ip = $null
                    if ($printer.PortName -match 'WSD') {
                        $locInfo = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\SWD\DAFWSDProvider\*" -ErrorAction SilentlyContinue |
                            Where-Object { $_.FriendlyName -and $_.FriendlyName.Replace('(', '').Replace(')', '') -match [Regex]::Escape($printer.Name) } |
                            Select-Object -ExpandProperty LocationInformation -First 1
                        if ($locInfo) {
                            $ipMatch = [regex]::Matches($locInfo, '\d{1,3}(\.\d{1,3}){3}')
                            if ($ipMatch.Count -gt 0) { $ip = $ipMatch[0].Value }
                        }
                    }
                    $list.Add([pscustomobject]@{
                            Name       = $printer.Name
                            PortName   = $printer.PortName
                            DriverName = $printer.DriverName
                            IP         = $ip
                            Context    = $ctx
                    })
                }
                return $list
            }

            $results = Get-PrinterInventoryInternal -ctx 'User' -pattern $excludePattern
            $results | ConvertTo-Json -Depth 3 | Set-Content -Path $outputPath -Encoding UTF8
        }

        Invoke-AsCurrentUser -ScriptBlock $scriptBlock -UseWindowsPowerShell -CaptureOutput -ArgumentList $ExcludePattern, $tempFile | Out-Null
    } catch {
        Write-Warning ("Failed to capture printers in user context: {0}" -f $_)
    }
} else {
    Write-Verbose 'No logged-on user detected; skipping user-context inventory.'
}

$systemPrinters = Get-PrinterInventory -Context 'System' -ExcludePattern $ExcludePattern
$userPrinters = @()
if (Test-Path $tempFile) {
    try {
        $userPrinters = Get-Content -Path $tempFile | ConvertFrom-Json
    } catch {
        Write-Warning ("Unable to parse user printer file: {0}" -f $_)
    } finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

$combined = @($systemPrinters + $userPrinters)
if (-not $combined) {
    Write-Warning 'No printers found in any context; updating Ninja field with placeholder text.'
    $html = '<p>No printers detected.</p>'
} else {
    $deduped = $combined |
        Group-Object Name, PortName, DriverName |
        ForEach-Object {
            if ($_.Count -gt 1) {
                $systemEntry = $_.Group | Where-Object { $_.Context -eq 'System' } | Select-Object -First 1
                if ($systemEntry) {
                    $systemEntry
                } else {
                    $_.Group | Select-Object -First 1
                }
            } else {
                $_.Group
            }
        }

    $html = Convert-ToHtmlTable -Objects $deduped
}

$html | Ninja-Property-Set-Piped -Name $PropertyName
Write-Host ("Updated Ninja property '{0}' with printer inventory." -f $PropertyName)
