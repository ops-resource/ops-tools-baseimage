<#
    .SYNOPSIS

    Prepares the system drive for optimization.


    .DESCRIPTION

    The PrepareFor-DiskOPtimization script removes deletes unused file and directories and then zeros out the unused disk space.
#>
[CmdletBinding()]
param()

Write-Host "Removing temp folders"
$tempfolders = @("C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Documents and Settings\*\Local Settings\temp\*", "C:\Users\*\Appdata\Local\Temp\*")
Remove-Item $tempfolders -ErrorAction SilentlyContinue -Force -Recurse

if ($SkipWindowsUpdates)
{
    Write-Host "Skipping cleanup"
    exit 0
}

try
{
    Write-Host "Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase"
    Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
}
catch
{
    Write-Host "Unable to reset base. Should be ok if patches have been slipstreamed."
}

$moduleExist = Get-Module servermanager

if ($moduleExist)
{
    Write-Host 'Get-WindowsFeature | ? { $_.InstallState -eq "Available" } | Uninstall-WindowsFeature -Remove'

    import-module servermanager
    Get-WindowsFeature | ? { $_.InstallState -eq 'Available' } | Uninstall-WindowsFeature -Remove
}

exit 0
