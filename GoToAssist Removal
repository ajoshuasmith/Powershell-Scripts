<#

Some customers had legacy GoToAssist from either vendors or previous IT teams and we wanted to remove them at mass. The uninstallers happen to be in different folders. 

- Joshua Smith

#>

# Define the base directory containing subfolders for GoToAssist Remote Support Customer
$baseDir = "C:\Program Files (x86)\GoToAssist Remote Support Customer"

# Get all subfolders under the base directory
$subfolders = Get-ChildItem -Path $baseDir -Directory

# Loop through each subfolder
foreach ($folder in $subfolders) {
    # Define the path to the uninstaller executable within the current subfolder
    $uninstallerPath = Join-Path -Path $folder.FullName -ChildPath "g2ax_uninstaller_customer.exe"
    
    # Check if the uninstaller executable exists
    if (Test-Path -Path $uninstallerPath) {
        # Start the uninstaller process with the specified arguments for silent uninstallation
        # -FilePath specifies the executable to run
        # -ArgumentList specifies the arguments to pass to the executable
        # -Wait makes the script wait for the process to exit before continuing
        # -PassThru allows the script to get the process object representing the newly started process
        Start-Process -FilePath $uninstallerPath -ArgumentList "/uninstall /silent" -Wait -PassThru
    } else {
        # Output a message if the uninstaller executable is not found in the current subfolder
        Write-Output "Uninstaller not found in $($folder.FullName)"
    }
}
