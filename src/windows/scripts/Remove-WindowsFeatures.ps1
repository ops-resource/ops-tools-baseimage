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

$featuresToRemove = @(
    'Desktop-Experience',
    'InkAndHandwritingServices',
    'Server-Media-Foundation',
    'Powershell-ISE',
    'FS-SMB1'                       # Remove file sharing via the SMB1 protocol (https://blogs.technet.microsoft.com/filecab/2016/09/16/stop-using-smb1/)
)
LogWrite -logFile $filePath -logText "Removing windows features: $($featuresToRemove -join ', ')"

foreach($feature in $featuresToRemove)
{
    try
    {
        if (Get-WindowsFeature -Name $feature -ErrorAction SilentlyContinue)
        {
            Remove-WindowsFeature -Name $feature
        }
    }
    catch
    {
        # Just continue
    }
}

$uninstallSuccess = $false
while(!$uninstallSuccess)
{
    LogWrite -logFile $filePath -logText "Attempting to uninstall features..."
    try
    {
        Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Available' } | Uninstall-WindowsFeature -Remove -ErrorAction Stop
        LogWrite -logFile $filePath -logText "Uninstall succeeded!"

        $uninstallSuccess = $true
    }
    catch
    {
        LogWrite -logFile $filePath -logText "Waiting two minutes before next attempt"
        Start-Sleep -Seconds 120
    }
}
