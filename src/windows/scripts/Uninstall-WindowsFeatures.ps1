<#
    .SYNOPSIS

    Uninstalls all windows features that are available but not activated


    .DESCRIPTION

    The Uninstall-WindowsFeatures script uninstalls all windows features that are available but not activated.

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

$uninstallSuccess = $false
while(!$uninstallSuccess)
{
    LogWrite -logFile $filePath -logText "Attempting to uninstall features..."
    try
    {
        $featuresToRemove = Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Available' }
        foreach($feature in $featuresToRemove)
        {
            try
            {
                Uninstall-WindowsFeature -Name $feature -Remove -ErrorAction Stop -Verbose
                LogWrite -logFile $filePath -logText "Uninstall succeeded!"
            }
            catch
            {
                Write-Output "Failed to uninstall windows feature: $($feature). Error was: $($_.Exception.ToString())"
            }
        }

        $uninstallSuccess = $true
    }
    catch
    {
        LogWrite -logFile $filePath -logText "Waiting two minutes before next attempt"
        Start-Sleep -Seconds 120
    }
}
