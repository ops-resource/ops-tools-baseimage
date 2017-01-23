<#
    .SYNOPSIS

    Removes all windows features that are available but not activated


    .DESCRIPTION

    The Remove-WindowsFeatures script removes all windows features that are available but not activated.

    NOTE: After removing the windows features the only way to get them back is to install them from
    the installation media.
#>
[CmdletBinding()]
param()

$uninstallSuccess = $false
while(!$uninstallSuccess)
{
    Write-Output "Attempting to uninstall features..."
    try
    {
        Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Available' } | Uninstall-WindowsFeature -Remove -ErrorAction Stop
        Write-Output "Uninstall succeeded!"

        $uninstallSuccess = $true
    }
    catch
    {
        Write-Output "Waiting two minutes before next attempt"
        Start-Sleep -Seconds 120
    }
}
