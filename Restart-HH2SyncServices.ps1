<# 

This was created for a customer who utilizes Sage 300 Construction and a software called HH2 which syncs invoices from a monitored Outlook folder into Sage 300. This ALWAYS gets hung up with a ton of processes "tsObject.exe" and the resolution was always to clear these processes and it would resume. Sage/HH2 did not ever fix this

- Joshua Smith

#>

# Stop all processes named tsObject.exe
$processes = Get-Process -Name tsObject -ErrorAction SilentlyContinue
if ($processes.Count -gt 1) {
    Stop-Process -Name tsObject
    Start-Sleep -Seconds 10
}

# Restart the hh2.MongoDB service
Restart-Service -Name hh2.MongoDB

# Wait for hh2.MongoDB service to start
while ((Get-Service -Name hh2.MongoDB).Status -ne "Running") {
    Start-Sleep -Seconds 10
}

# Restart the Hydrous.Host service (hh2 Synchronization Service)
Restart-Service -Name Hydrous.Host

