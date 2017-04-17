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

# Appx removal
function Remove-WindowsApps
{
    LogWrite -logFile $filePath -logText "Removing all apps and provisioned appx packages for this machine ..."
    Get-AppxPackage -AllUsers | Remove-AppxPackage -erroraction silentlycontinue
    Get-AppxPackage -AllUsers | Remove-AppxPackage -erroraction silentlycontinue
    Get-AppxProvisionedPackage -online | Remove-AppxProvisionedPackage -online
}

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


# Registry change functions
# Load default user hive
function Load-DefaultRegistryHive
{
    reg load "$reglocation" c:\users\default\ntuser.dat
}

# unload default user hive
function Unload-DefaultRegistryHive
{
    [gc]::collect()
    reg unload "$reglocation"
}

# Set current user settings
function Set-RegistryForAllUsers
{
    LogWrite -logFile $filePath -logText "Disabling Suggested Apps, Feedback, Lockscreen Spotlight, and File Explorer ads: "
    LogWrite -logFile $filePath -logText "Start menu adds ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\" /T REG_DWORD /V "SystemPaneSuggestionsEnabled" /D 0 /F

    LogWrite -logFile $filePath -logText "Lockscreen suggestions, rotating pictures ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\CurrentVersion\ContentDeliveryManager\" /T REG_DWORD /V "SoftLandingEnabled" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\CurrentVersion\ContentDeliveryManager\" /T REG_DWORD /V "RotatingLockScreenEnable" /D 0 /F

    LogWrite -logFile $filePath -logText "Preinstalled apps, Minecraft Twitter ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\CurrentVersion\ContentDeliveryManager\" /T REG_DWORD /V "PreInstalledAppsEnabled" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\CurrentVersion\ContentDeliveryManager\" /T REG_DWORD /V "OEMPreInstalledAppsEnabled" /D 0 /F

    LogWrite -logFile $filePath -logText "Stop MS shoehorning apps quietly into your profile ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\CurrentVersion\ContentDeliveryManager\" /T REG_DWORD /V "SilentInstalledAppsEnabled" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\CurrentVersion\ContentDeliveryManager\" /T REG_DWORD /V "ContentDeliveryAllowed" /D 0 /F

    LogWrite -logFile $filePath -logText "Ads in Explorer ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" /T REG_DWORD /V "ShowSyncProviderNotifications" /D 0 /F

    LogWrite -logFile $filePath -logText "Disabling auto update and download of Windows Store Apps ..."
    Reg Add "$reglocation\SOFTWARE\Policies\Microsoft\WindowsStore\" /T REG_DWORD /V "AutoDownload" /D 2 /F

    LogWrite -logFile $filePath -logText "Disabling Onedrive startup run user settings ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run\" /T REG_BINARY /V "OneDrive" /D 0300000021B9DEB396D7D001 /F

    LogWrite -logFile $filePath -logText "Filter web content through smartscreen ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost\" /T REG_DWORD /V "EnableWebContentEvaluation" /D 0 /F

    LogWrite -logFile $filePath -logText "Let websites provide local content by accessing language list ..."
    Reg Add "$reglocation\Control Panel\International\User Profile\" /T REG_DWORD /V "HttpAcceptLanguageOptOut" /D 1 /F

    LogWrite -logFile $filePath -logText "Let apps share and sync non-explicitly paired wireless devices over uPnP ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled\" /T REG_SZ /V "Value" /D DENY /F

    LogWrite -logFile $filePath -logText "Don't ask for feedback ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Siuf\Rules\" /T REG_DWORD /V "NumberOfSIUFInPeriod" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\Siuf\Rules\" /T REG_DWORD /V "PeriodInNanoSeconds" /D 0 /F

    LogWrite -logFile $filePath -logText "Stopping Cortana/Microsoft from getting to know you ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Personalization\Settings\" /T REG_DWORD /V "AcceptedPrivacyPolicy" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language\" /T REG_DWORD /V "Enabled" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\InputPersonalization\" /T REG_DWORD /V "RestrictImplicitTextCollection" /D 1 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\InputPersonalization\" /T REG_DWORD /V "RestrictImplicitInkCollection" /D 1 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore\" /T REG_DWORD /V "HarvestContacts" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\Input\TIPC\" /T REG_DWORD /V "Enabled" /D 0 /F

    LogWrite -logFile $filePath -logText "Disabling Cortana and Bing search user settings ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\" /T REG_DWORD /V "CortanaEnabled" /D 0 /F

    LogWrite -logFile $filePath -logText "Below takes search bar off the taskbar, personal preference ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\" /T REG_DWORD /V "SearchboxTaskbarMode" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\" /T REG_DWORD /V "BingSearchEnabled" /D 0 /F
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\" /T REG_DWORD /V "DeviceHistoryEnabled" /D 0 /F

    LogWrite -logFile $filePath -logText "Stopping Cortana from remembering history ..."
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Search\" /T REG_DWORD /V "HistoryViewEnabled" /D 0 /F
}

# Set local machine policies
function Set-RegistryForMachine
{
    LogWrite -logFile $filePath -logText "Updating machine registry"
    LogWrite -logFile $filePath -logText "Local Policy/Computer Config/Admin Templates/Windows Components"
    LogWrite -logFile $filePath -logText "/AppPrivacy"
    LogWrite -logFile $filePath -logText "Account Info"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessAccountInfo"/D 2 /F

    LogWrite -logFile $filePath -logText "Calendar"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessCalendar"/D 2 /F

    LogWrite -logFile $filePath -logText "Call History"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessCallHistory" /D 2 /F

    LogWrite -logFile $filePath -logText "Camera"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessCamera" /D 2 /F

    LogWrite -logFile $filePath -logText "Contacts"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessContacts" /D 2 /F

    LogWrite -logFile $filePath -logText "Email"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessEmail" /D 2 /F

    LogWrite -logFile $filePath -logText "Location"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessLocation" /D 2 /F

    LogWrite -logFile $filePath -logText "Messaging"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessMessaging" /D 2 /F

    LogWrite -logFile $filePath -logText "Microphone"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessMicrophone" /D 2 /F

    LogWrite -logFile $filePath -logText "Motion"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessMotion" /D 2 /F

    LogWrite -logFile $filePath -logText "Notifications"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessNotifications" /D 2 /F

    LogWrite -logFile $filePath -logText "Make Phone Calls"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessPhone" /D 2 /F

    LogWrite -logFile $filePath -logText "Radios"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessRadios" /D 2 /F

    LogWrite -logFile $filePath -logText "Access trusted devices"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsAccessTrustedDevices" /D 2 /F

    LogWrite -logFile $filePath -logText "Sync with devices"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy\" /T REG_DWORD /V "LetAppsSyncWithDevices" /D 2 /F

    LogWrite -logFile $filePath -logText "/Application Compatibility"
    LogWrite -logFile $filePath -logText "Turn off Application Telemetry"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\" /T REG_DWORD /V "AITEnable" /D 0 /F

    LogWrite -logFile $filePath -logText "Turn off inventory collector"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\" /T REG_DWORD /V "DisableInventory" /D 1 /F

    LogWrite -logFile $filePath -logText "Turn off steps recorder"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat\" /T REG_DWORD /V "DisableUAR" /D 1 /F

    LogWrite -logFile $filePath -logText "/Cloud Content"
    LogWrite -logFile $filePath -logText "Do not show Windows Tips"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\" /T REG_DWORD /V "DisableSoftLanding" /D 1 /F

    LogWrite -logFile $filePath -logText "Turn off Consumer Experiences"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent\" /T REG_DWORD /V "DisableWindowsConsumerFeatures" /D 1 /F

    LogWrite -logFile $filePath -logText "/Data Collection and Preview Builds"
    LogWrite -logFile $filePath -logText "Set Telemetry to basic"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\" /T REG_DWORD /V "AllowTelemetry" /D 0 /F

    LogWrite -logFile $filePath -logText "Disable pre-release features and settings"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds\" /T REG_DWORD /V "EnableConfigFlighting" /D 0 /F

    LogWrite -logFile $filePath -logText "Do not show feedback notifications"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection\" /T REG_DWORD /V "DoNotShowFeedbackNotifications" /D 1 /F

    LogWrite -logFile $filePath -logText "/Delivery optimization"
    LogWrite -logFile $filePath -logText "Disable DO; set to 1 to allow DO over LAN only"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization\" /T REG_DWORD /V "DODownloadMode" /D 0 /F

    LogWrite -logFile $filePath -logText "Non-GPO DO settings, may be redundant after previous."
    Reg Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config\" /T REG_DWORD /V "DownloadMode" /D 0 /F
    Reg Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config\" /T REG_DWORD /V "DODownloadMode" /D 0 /F

    LogWrite -logFile $filePath -logText "/Location and Sensors"
    LogWrite -logFile $filePath -logText "Turn off location"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\" /T REG_DWORD /V "DisableLocation" /D 1 /F

    LogWrite -logFile $filePath -logText "Turn off Sensors"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors\" /T REG_DWORD /V "DisableSensors" /D 1 /F

    LogWrite -logFile $filePath -logText "/Microsoft Edge"
    LogWrite -logFile $filePath -logText "Always send do not track"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main\" /T REG_DWORD /V "DoNotTrack" /D 1 /F

    LogWrite -logFile $filePath -logText "/OneDrive"
    LogWrite -logFile $filePath -logText "Prevent usage of OneDrive"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive\" /T REG_DWORD /V "DisableFileSyncNGSC" /D 1 /F
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive\" /T REG_DWORD /V "DisableFileSync" /D 1 /F

    LogWrite -logFile $filePath -logText "/Search"
    LogWrite -logFile $filePath -logText "Disallow Cortana"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\" /T REG_DWORD /V "AllowCortana" /D 0 /F

    LogWrite -logFile $filePath -logText "Disallow Cortana on lock screen"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\" /T REG_DWORD /V "AllowCortanaAboveLock" /D 0 /F

    LogWrite -logFile $filePath -logText "Disallow web search from desktop search"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\" /T REG_DWORD /V "DisableWebSearch" /D 1 /F

    LogWrite -logFile $filePath -logText "Don't search the web or dispaly web results in search"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search\" /T REG_DWORD /V "ConnectedSearchUseWeb" /D 0 /F

    LogWrite -logFile $filePath -logText "/Store"
    LogWrite -logFile $filePath -logText "Turn off Automatic download/install of app updates - comment in if you want to eliminate the store"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore\" /T REG_DWORD /V "AutoDownload" /D 2 /F

    LogWrite -logFile $filePath -logText "Disable all apps from store, left disabled by default"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore\" /T REG_DWORD /V "DisableStoreApps" /D 1 /F

    LogWrite -logFile $filePath -logText "Turn off Store, left disabled by default"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore\" /T REG_DWORD /V "RemoveWindowsStore" /D 1 /F

    LogWrite -logFile $filePath -logText "/Sync your settings"
    LogWrite -logFile $filePath -logText "Do not sync (anything)"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\" /T REG_DWORD /V "DisableSettingSync" /D 2 /F

    LogWrite -logFile $filePath -logText "Disallow users to override this"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync\" /T REG_DWORD /V "DisableSettingSyncUserOverride" /D 1 /F

    LogWrite -logFile $filePath -logText "/Windows Update"
    LogWrite -logFile $filePath -logText "Turn off featured software notifications through WU (basically ads)"
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\" /T REG_DWORD /V "EnableFeaturedSoftware" /D 0 /F

    LogWrite -logFile $filePath -logText "--Non Local-GP Settings--"
    LogWrite -logFile $filePath -logText "Disabling advertising info and device metadata collection for this machine"
    Reg Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo\" /T REG_DWORD /V "Enabled" /D 0 /F
    Reg Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata\" /V "PreventDeviceMetadataFromNetwork" /T REG_DWORD /D 1 /F

    LogWrite -logFile $filePath -logText "Prevent apps on other devices from opening apps on this one"
    Reg Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SmartGlass\" /T REG_DWORD /V "UserAuthPolicy " /D 0 /F

    LogWrite -logFile $filePath -logText "Prevent using sign-in info to automatically finish setting up after an update"
    Reg Add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\" /T REG_DWORD /V "ARSOUserConsent" /D 2 /F

    LogWrite -logFile $filePath -logText "Disable Malicious Software Removal Tool through WU, and CEIP.  Left MRT enabled by default."
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\MRT\" /T REG_DWORD /V "DontOfferThroughWUAU" /D 1 /F
    Reg Add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows\" /T REG_DWORD /V "CEIPEnable" /D 0 /F

    # User Config/Admin Templates/Windows Components (work in progress, don't seem to work)
    # /Cloud Content
    # Turn off spotlight on lock screen
    #Reg Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{8F5431C8-CECD-4977-92D5-0C52E9705084}User\Software\Policies\Microsoft\Windows\CloudContent\" /T REG_DWORD /V "ConfigureWindowsSpotlight" /D 2 /F
    #Reg Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{8F5431C8-CECD-4977-92D5-0C52E9705084}User\Software\Policies\Microsoft\Windows\CloudContent\" /T REG_DWORD /V "IncludeEnterpriseSpotlight" /D 0 /F

    # Do not suggest 3rd party content
    #Reg Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{8F5431C8-CECD-4977-92D5-0C52E9705084}User\Software\Policies\Microsoft\Windows\CloudContent\" /T REG_DWORD /V "DisableThirdPartySuggestions" /D 1 /F

    # Turn off all spotlight features
    #Reg Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{8F5431C8-CECD-4977-92D5-0C52E9705084}User\Software\Policies\Microsoft\Windows\CloudContent\" /T REG_DWORD /V "DisableWindowsSpotlightFeatures" /D 1 /F
}

# Call correct registry changing functions
function Update-Registry
{
    LogWrite -logFile $filePath -logText "Setting registry for default user ..."
    $reglocation = "HKCU"
    Set-RegistryForAllUsers

    $reglocation = "HKLM\AllProfile"
    Load-DefaultRegistryHive; Set-RegistryForAllUsers; unLoad-DefaultRegistryHive

    LogWrite -logFile $filePath -logText "Setting policies for local machine ..."
    $reglocation = $null
    Set-RegistryForMachine

    LogWrite -logFile $filePath -logText "Registry updates complete."
}

LogWrite -logFile $filePath -logText "Removing windows store and apps ..."

Remove-WindowsApps
Remove-ScheduledTasks
Disable-Services
Update-Registry

LogWrite -logFile $filePath -logText "Windows store removal complete"
