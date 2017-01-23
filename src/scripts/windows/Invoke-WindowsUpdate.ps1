<#
    .SYNOPSIS

    Executes the 'windows update' commands to install the latest patches for the current operating system.


    .DESCRIPTION

    The Invoke-WindowsUpdate script executes the 'windows update' commands to install the latest patches
    for the current operating system. This script assumes that the 'PSWindowsUpdate'
    (see here: https://www.powershellgallery.com/packages/PSWindowsUpdate) module is installed.

    NOTE: This invocation may not be able to install all available patches for the operating system
    because patches should be applied in the correct order and some patches require a reboot before
    the next patch may be installed. Therefore it might be necessary to invoke this script multiple
    times with reboots in the appropriate times.
#>
[CmdletBinding()]
param()

$ProgressPreference = 'SilentlyContinue'

Get-WUInstall `
    -WindowsUpdate `
    -AcceptAll `
    -UpdateType Software `
    -IgnoreReboot
