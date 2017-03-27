<#
    .SYNOPSIS

    Prepares the system drive for optimization.


    .DESCRIPTION

    The PrepareFor-DiskOPtimization script removes deletes unused file and directories and then zeros out the unused disk space.
#>
[CmdletBinding()]
param()

$ProgressPreference="SilentlyContinue"

# NOTE: this script should not log anything to disk because it will be in charge of cleaning the disk just prior to
#       defragmentation and zero-ing of the disk space. Writing log files here defeats the purpose!

Write-Output "Removing temp folders"
$tempfolders = @("C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Documents and Settings\*\Local Settings\temp\*", "C:\Users\*\Appdata\Local\Temp\*")
Remove-Item $tempfolders -ErrorAction SilentlyContinue -Force -Recurse

if ($SkipWindowsUpdates)
{
    Write-Output "Skipping cleanup"
    exit 0
}

try
{
    Write-Output "Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase"
    Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
}
catch
{
    Write-Output "Unable to reset base. Should be ok if patches have been slipstreamed."
}

$moduleExist = Get-Module servermanager -InformationAction SilentlyContinue -WarningAction SilentlyContinue

if ($moduleExist)
{
    Write-Output 'Get-WindowsFeature | ? { $_.InstallState -eq "Available" } | Uninstall-WindowsFeature -Remove'

    import-module servermanager -InformationAction SilentlyContinue -WarningAction SilentlyContinue
    Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Available' } | Uninstall-WindowsFeature -Remove
}

exit 0
