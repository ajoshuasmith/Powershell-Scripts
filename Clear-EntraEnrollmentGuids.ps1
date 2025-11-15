<#

This was created to speed up some Entra ID joins on computers that may fail (Azure AD Join Error 801800a) and say it was already joined but it clearly is not. 

You can do this by deleting all GUIDs under HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments
Make sure to NOT delete Context, Ownership, Status and ValidNodePaths.

- Joshua Smith

#>

# Full Registry path
$FullRegistryPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments"

# Get all registry subkeys under the specified path
try {
    $Subkeys = Get-Item -LiteralPath "Registry::$FullRegistryPath" | Get-ItemProperty | ForEach-Object { $_.PSChildName }

    # Filter subkeys based on the specified format
    $FilteredSubkeys = $Subkeys | Where-Object { $_ -match '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$' }

    if ($FilteredSubkeys.Count -eq 0) {
        Write-Host "No matching registry folders found under '$FullRegistryPath'."
    } else {
        foreach ($Subkey in $FilteredSubkeys) {
            $SubkeyPath = Join-Path -Path "Registry::$FullRegistryPath" -ChildPath $Subkey
            Remove-Item -Path $SubkeyPath -Recurse -Force -ErrorAction Stop
            Write-Host "Registry folder '$SubkeyPath' removed successfully."
        }

        Write-Host "All matching registry folders removed."
    }
} catch {
    Write-Host "Error: $_"
}
