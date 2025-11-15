<#

This was created to automate enabling Windows Defender after removal of Third Party AVs

- Joshua Smith
#>

# Set the MAPS (Microsoft Active Protection Service) reporting level to Advanced
Set-MpPreference -MAPSReporting Advanced

# Set the sample submission consent level to send all samples automatically
Set-MpPreference -SubmitSamplesConsent SendAllSamples

# Ensure real-time monitoring is enabled
Set-MpPreference -DisableRealtimeMonitoring $false

# Ensure IOAV (Internet Of AV) protection is enabled
Set-MpPreference -DisableIOAVProtection $false

# Create a registry key for Real-Time Protection settings if it doesn't exist
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "Real-Time Protection" -Force

# Enable behavior monitoring by setting the corresponding registry value to 0 (disabled state)
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 0 -PropertyType DWORD -Force

# Ensure on-access protection is enabled by setting the registry value to 0 (disabled state)
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 0 -PropertyType DWORD -Force

# Ensure that real-time scans are enabled by setting the registry value to 0 (disabled state)
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableScanOnRealtimeEnable" -Value 0 -PropertyType DWORD -Force

# Ensure that Windows Defender AntiSpyware is enabled by setting the registry value to 0 (disabled state)
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 0 -PropertyType DWORD -Force

# Start the Windows Defender service
start-service WinDefend

# Start the Network Inspection System (NIS) service
start-service WdNisSvc
