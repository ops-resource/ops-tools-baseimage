<#
    .SYNOPSIS

    Removes all the windows store apps.


    .DESCRIPTION

    The Remove-WindowsStoreApps script removes all windows store apps.
    Original code here: https://community.spiceworks.com/scripts/show/3298-windows-10-decrapifier-v2

    NOTE: After removing the windows store apps the only way to get them back is to get them from the store after you
    re-enable the store in the registry
#>
[CmdletBinding()]
param()

$ProgressPreference="SilentlyContinue"

function LogWrite
{
    param (
        [string] $logText,
        [string] $logFile
    )

    $now = Get-Date -format s

    Add-Content -Path $logfile -Value "$now $logText"
    Write-Output $logstring
}

$filePath = "$($env:TEMP)\$($MyInvocation.MyCommand.Name).started.txt"
LogWrite -logFile $filePath -logText "Starting $($MyInvocation.MyCommand.Name)"

function Remove-WindowsApps
{
    LogWrite -logFile $filePath -logText "Removing all apps and provisioned appx packages for this machine ..."
    Get-AppxPackage -AllUsers | Remove-AppxPackage -erroraction silentlycontinue
    Get-AppxPackage -AllUsers | Remove-AppxPackage -erroraction silentlycontinue
    Get-AppxProvisionedPackage -online | Remove-AppxProvisionedPackage -online
}

LogWrite -logFile $filePath -logText "Removing windows store and apps ..."

Remove-WindowsApps

LogWrite -logFile $filePath -logText "Windows store removal complete"
