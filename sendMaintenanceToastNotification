<#

This was created to notify end users of upcoming patching so they can keep their machines powered on and would give them a cool little toast with a GIF to grab their attention. This was originally a CyberDrain script.

- Joshua Smith

#>

# Install the BurntToast module for creating toast notifications
Install-Module -Name BurntToast

# Install the RunAsUser module to run scripts as the current user
Install-module -Name RunAsUser

# Execute the following block of code as the current user
invoke-ascurrentuser -scriptblock {

    # Define a hero image for the notification
    $heroimage = New-BTImage -Source 'https://image.here' -HeroImage

    # Define the first line of text for the toast notification
    $Text1 = New-BTText -Content "Message from IT"

    # Define the second line of text for the toast notification
    $Text2 = New-BTText -Content "Reminder! Please keep your workstation/laptop powered on and connected to the internet for mandatory maintenance this Sunday at 12 AM! Please acknowledge this message."

    # Define a button for the toast notification that dismisses the toast when clicked
    $Button = New-BTButton -Content "Acknowledge" -Dismiss

    # The following commented-out section is for additional buttons and options
    #$Button2 = New-BTButton -Content "Reboot now" -Arguments "ToastReboot:" -ActivationType Protocol
    #$5Min = New-BTSelectionBoxItem -Id 5 -Content '5 minutes'
    #$10Min = New-BTSelectionBoxItem -Id 10 -Content '10 minutes'
    #$1Hour = New-BTSelectionBoxItem -Id 60 -Content '1 hour'
    #$4Hour = New-BTSelectionBoxItem -Id 240 -Content '4 hours'
    #$1Day = New-BTSelectionBoxItem -Id 1440 -Content '1 day'
    #$Items = $5Min, $10Min, $1Hour, $4Hour, $1Day
    #$SelectionBox = New-BTInput -Id 'SnoozeTime' -DefaultSelectionBoxItemId 10 -Items $Items

    # Define the action for the toast notification which includes the acknowledge button
    $action = New-BTAction -Buttons $Button

    # Define the visual binding for the toast notification, linking the hero image and text
    $Binding = New-BTBinding -Children $text1, $text2 -HeroImage $heroimage

    # Define the visual component of the toast notification
    $Visual = New-BTVisual -BindingGeneric $Binding

    # Define the content of the toast notification, including visual and action components
    $Content = New-BTContent -Visual $Visual -Actions $action

    # Submit the toast notification with the defined content
    Submit-BTNotification -Content $Content
}
