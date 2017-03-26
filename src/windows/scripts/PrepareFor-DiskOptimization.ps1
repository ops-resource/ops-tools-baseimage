<#
    .SYNOPSIS

    Prepares the system drive for optimization.


    .DESCRIPTION

    The PrepareFor-DiskOPtimization script removes deletes unused file and directories and then zeros out the unused disk space.
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

LogWrite -logFile $filePath -logText "Removing temp folders"
$tempfolders = @("C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Documents and Settings\*\Local Settings\temp\*", "C:\Users\*\Appdata\Local\Temp\*")
Remove-Item $tempfolders -ErrorAction SilentlyContinue -Force -Recurse

if ($SkipWindowsUpdates)
{
    LogWrite -logFile $filePath -logText "Skipping cleanup"
    exit 0
}

try
{
    LogWrite -logFile $filePath -logText "Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase"
    Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
}
catch
{
    LogWrite -logFile $filePath -logText "Unable to reset base. Should be ok if patches have been slipstreamed."
}

$moduleExist = Get-Module servermanager -InformationAction SilentlyContinue -WarningAction SilentlyContinue

if ($moduleExist)
{
    LogWrite -logFile $filePath -logText 'Get-WindowsFeature | ? { $_.InstallState -eq "Available" } | Uninstall-WindowsFeature -Remove'

    import-module servermanager -InformationAction SilentlyContinue -WarningAction SilentlyContinue
    Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Available' } | Uninstall-WindowsFeature -Remove
}

exit 0
