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

# Scheduled task removal
# Tasks:
#     Send Smartscreen filtering data to MS,
#     CEIP options that used to be able to be disabled earlier Windows (now mandatory) - functions self explanatory based on the name
#     Send error reports in the queue to MS, installation of ads, cloud content, etc
function Remove-ScheduledTasks
{
    $tasksToRemove = @(
        "Consolidator",
        "GatherNetworkInfo",
        "KernelCeipTask",
        "Microsoft Compatibility Appraiser",
        "Microsoft-Windows-DiskDiagnosticDataCollector",
        "QueueReporting",
        "SmartScreenSpecific",
        "UsbCeip"
    )

    foreach($task in $tasksToRemove)
    {
        LogWrite -logFile $filePath -logText "Disabling unecessary scheduled task $($task) ..."
        Get-Scheduledtask -TaskName $task | Disable-scheduledtask
    }
}

# Disable services
function Disable-Services
{
    $servicesToDisable = @(
        'AppReadiness',
        'AppXSvc',
        'Diagtrack',
        'DmwApPushService',
        'OneSyncSvc',
        'tiledatamodelsvc',
        'ualsvc',
        'XblAuthManager',
        'XblGameSave'
    )

    foreach($service in $servicesToDisable)
    {
        LogWrite -logFile $filePath -logText "Stopping and disabling service $($service) ..."
        Get-Service -Name $service | stop-service -passthru

        # Apparently setting the service state in powershell doesn't always stick, so ...
        $path = "HKLM:\SYSTEM\CurrentControlSet\Services\$($service)"
        if (Test-Path $path)
        {
            Set-ItemProperty -Path $path -Name Start -Value 4 -Force
        }
    }
}

function AddOrUpdate-RegistryValue
{
    [CmdletBinding()]
    param(
        [string] $path,
        [string] $key,
        $type,
        $value
    )

    if (-not (Test-Path $path))
    {
        New-Item -Path $path
    }

    Set-ItemProperty -Path $path -Name $key -Type $type -Value $value -Force
}

# Set local machine policies
function Set-RegistryForMachine
{
    LogWrite -logFile $filePath -logText "Updating machine registry"
    LogWrite -logFile $filePath -logText "Disable pre-release features and settings"
    AddOrUpdate-RegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds\" -key "EnableConfigFlighting" -type DWORD -value 0

    LogWrite -logFile $filePath -logText "/Store"
    LogWrite -logFile $filePath -logText "Turn off Automatic download/install of app updates - comment in if you want to eliminate the store"
    AddOrUpdate-RegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore\" -key "AutoDownload" -type DWORD -value 2

    LogWrite -logFile $filePath -logText "Disable all apps from store, left disabled by default"
    AddOrUpdate-RegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore\" -key "DisableStoreApps" -type DWORD -value 1

    LogWrite -logFile $filePath -logText "Turn off Store, left disabled by default"
    AddOrUpdate-RegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore\" -key "RemoveWindowsStore" -type DWORD -value 1

    LogWrite -logFile $filePath -logText "/Windows Update"
    LogWrite -logFile $filePath -logText "Turn off featured software notifications through WU (basically ads)"
    AddOrUpdate-RegistryValue -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\" -key "EnableFeaturedSoftware" -type DWORD -value 0
}

LogWrite -logFile $filePath -logText "Removing windows store and apps ..."

Remove-ScheduledTasks
Disable-Services
Set-RegistryForMachine

LogWrite -logFile $filePath -logText "Windows store removal complete"
