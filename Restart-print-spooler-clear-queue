<#

Everyone hates printers and queues always get backed up. 

- Joshua Smith

#>

# Stop Print Spooler Service
Get-Service -Name Spooler | Stop-Service -Force -Verbose

# Wait for a few seconds (optional)
Start-Sleep -Seconds 5

# Clear Print Spooler Queue
$printQueuePath = "$env:SystemRoot\system32\spool\printers"
Get-ChildItem -Path $printQueuePath -File | Remove-Item -Force -Verbose

# Start Print Spooler Service
Get-Service -Name Spooler | Start-Service -Verbose
