# Detects latest Public IP/ISP using free online api's & writes to custom fields
# Only checks for new ISP if a new IP is detected, to avoid ipinfo.io polling limit
# Expects Device scope 'publicIP' and 'isp' custom fields

# Returns the latest public IP via ipify
Function getPublicIP {
  $ip = (Invoke-WebRequest -uri "api.ipify.org" -usebasicparsing).Content
  return $ip
}

# Returns the latest ISP via ipinfo.io
Function getISP {
  $ipInfo = Invoke-RestMethod http://ipinfo.io/json
  $ISP = $ipInfo.org # org property is ISP Organization
  return $ISP
}

# Seed initial publicIP & isp values
$cfIP = Ninja-Property-Get publicIP
# Check if publicIP has been set
if ($null -eq $cfIP) {
  Write-Host "Seeding publicIP and isp custom fields."
  # Get current IP and ISP
  $currentIP = getPublicIP
  $currentISP = getISP
  # Set IP & ISP custom field values
  Ninja-Property-Set publicIP $currentIP
  Ninja-Property-Set isp $currentISP
  # Get IP and ISP from custom fields
  $cfIP = Ninja-Property-Get publicIP
  $cfISP = Ninja-Property-Get isp
  Write-Host "Public IP Seeded: $($cfIP)"
  Write-Host "ISP Seeded: $($cfISP)"
  Exit 0
}

# Checks/updates public IP and isp custom fields
# Get current IP and stored IP for comparison
$currentIP = getPublicIP
$cfIP = Ninja-Property-Get publicIP
# Check for new IP & set custom field value
if ($currentIP -ne "$cfIP") {
  Write-Host "New Public IP Detected."
  Write-Host "New IP: $($currentIP)"
  Write-Host "Previous IP: $($cfIP)"
  Ninja-Property-Set publicIP $currentIP
  
  # Get current ISP and stored ISP for comparison
  $currentISP = getISP
  $cfISP = Ninja-Property-Get isp
  # Check for new ISP & set custom field value
  if ($currentISP -ne $cfISP) {
    Write-Host "New ISP Detected."
    Write-Host "New ISP: $($currentISP)"
    Write-Host "Previous ISP: $($cfISP)"
    Ninja-Property-Set isp $currentISP
    } else {
      Write-Host "No change to ISP"
    }
  } else {
  Write-Host "No change to IP/ISP"
}
Exit 0
