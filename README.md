# PowerShell Scripts

This is the place where I drop the PowerShell and batch files I’ve relied on since working help desk, through consulting, and now as a Director of Technology. Some came out of late-night troubleshooting, others from MSP automation projects, and a few were lifted from community examples and cleaned up for production.

The goals:

- centralize the one-off scripts that used to live on my laptop or inside RMM policies;
- keep a working history of how I solve repeat problems (printers, enrollment cleanup, tiered OU builds, etc.);
- show practical examples of how I approach automation, not ChatGPT boilerplate.

## Notes and Expectations

- Scripts follow verb-noun naming so they’re easy to find (`Set-LocalDefaultPasswords.ps1`, `Reset-DisplayAdapters.ps1`, etc.).
- Some rely on NinjaOne cmdlets (`Ninja-Property-Set`), RunAsUser, or AD/Entra modules—read the header comments before running them outside those environments.
- Code here is meant to be reused. Personalize the parameters, tweak the logging, or fork it for your own toolkit.

## High-Usage Scripts

- `Get-NinjaPrinterInventory.ps1` – captures printers from both SYSTEM and logged-in user contexts, pushes an HTML table to a Ninja custom field.
- `Set-LocalDefaultPasswords.ps1` – resets local accounts with secure inputs and `SupportsShouldProcess`.
- `Add-DnsSuffixSearchList.ps1` – appends required DNS suffixes without wiping the existing list.
- `Reset-DisplayAdapters.ps1` / `Reset-PrintSpoolerQueue.ps1` – quick remediation for stuck GPUs or printers.
- `Set-Edge/Chrome/FirefoxPasswordPolicy.ps1` – turns browser password managers on/off and clears stored creds when policy changes.
- `Set-EntraImmutableIdFromAD.ps1` – prevents duplicate cloud accounts during Entra Connect migrations.

Most scripts can be run directly once execution policy allows it:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\Reset-DisplayAdapters.ps1 -DelaySeconds 5
```
