# List of applications to promote (make their notification area icons always visible)

$promotedApps = @"
Teams.exe
OneDrive.exe
ms-teams.exe
OUTLOOK.EXE
"@ -split "`n" | % { $_.trim() }

# Base registry path for notification icon settings
$BaseRegPath = "HKCU:\Control Panel\NotifyIconSettings"

# Loop through each application in the promotedApps list
foreach ($app in $promotedApps) {
    # Find registry entries for the application that are not already promoted
    foreach ($Icon in (Get-ItemProperty "$BaseRegPath\*" | Where-Object { $_.ExecutablePath -like "*\$app" -and $_.IsPromoted -ne 1}).PSChildName) {
        # Set the IsPromoted property to 1 to promote the icon
        Set-ItemProperty "$BaseRegPath\$Icon" -Name 'IsPromoted' -Value 1
    }
}

# Commented-out section for hiding specific applications' icons
#$HideApps = @"
#vmware-tray.exe
#"@ -split "`n" | % { $_.trim() }
#
#$BaseRegPath = "HKCU:\Control Panel\NotifyIconSettings"
#foreach ($app in $HideApps) {
#    foreach ($Icon in (Get-ItemProperty "$BaseRegPath\*" | Where-Object { $_.ExecutablePath -like "*\$app" -and $_.IsPromoted -ne 0}).PSChildName) {
#        Set-ItemProperty "$BaseRegPath\$Icon" -Name 'IsPromoted' -Value 0
#    }
#}
