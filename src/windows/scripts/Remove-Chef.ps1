<#
    .SYNOPSIS

    Removes the Chef installation.


    .DESCRIPTION

    The Remove-Chef script removes Chef from the machine.
#>
[CmdletBinding()]
param()

$ProgressPreference="SilentlyContinue"

Write-Output "Uninstall Chef..."
if (Test-Path "c:\windows\temp\chef.msi")
{
    Start-Process MSIEXEC.exe '/uninstall c:\windows\temp\chef.msi /quiet' -Wait
}
