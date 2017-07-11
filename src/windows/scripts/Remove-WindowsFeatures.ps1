<#
    .SYNOPSIS

    Removes all windows features that are available but not activated


    .DESCRIPTION

    The Remove-WindowsFeatures script removes all windows features that are available but not activated.
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
        Write-Output "Trying to remove Windows feature: $($feature) ..."
        if (Get-WindowsFeature -Name $feature -ErrorAction SilentlyContinue)
        {
            Remove-WindowsFeature -Name $feature -Verbose
        }
    }
    catch
    {
        Write-Output "Failed to remove windows feature: $($feature). Error was: $($_.Exception.ToString())"
    }
}
