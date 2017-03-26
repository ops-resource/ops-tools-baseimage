
param($global:RestartRequired=0,
        $global:MoreUpdates=0,
        $global:MaxCycles=100,
        $MaxUpdatesPerCycle=500)

$ErrorActionPreference="Stop"
$ProgressPreference="SilentlyContinue"

# --------------- START SCRIPT FUNCTIONS -------------------------------

function Check-ContinueRestartOrEnd()
{
    param (
        [string] $logFile
    )

    $RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $RegistryEntry = "InstallWindowsUpdates"
    switch ($global:RestartRequired)
    {
        0 {
            $prop = (Get-ItemProperty $RegistryKey).$RegistryEntry
            if ($prop)
            {
                LogWrite -logText "Restart Registry Entry Exists - Removing It" -logFile $logFile
                Remove-ItemProperty -Path $RegistryKey -Name $RegistryEntry -ErrorAction SilentlyContinue
            }

            LogWrite -logText "No Restart Required" -logFile $logFile
            Check-WindowsUpdates -logFile $logFile

            if (($global:MoreUpdates -eq 1) -and ($script:Cycles -le $global:MaxCycles))
            {
                Install-WindowsUpdates -logFile $logFile
            }
            elseif ($script:Cycles -gt $global:MaxCycles)
            {
                LogWrite -logText "Exceeded Cycle Count - Stopping" -logFile $logFile
                EnableWinRm -logFile $logFile
            }
            else
            {
                LogWrite -logText "Done Installing Windows Updates" -logFile $logFile
                EnableWinRm -logFile $logFile
            }
        }
        1 {
            $prop = (Get-ItemProperty $RegistryKey).$RegistryEntry
            if (-not $prop)
            {
                LogWrite -logText "Restart Registry Entry Does Not Exist - Creating It" -logFile $logFile
                Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File $($script:ScriptPath) -MaxUpdatesPerCycle $($MaxUpdatesPerCycle)"
            }
            else
            {
                LogWrite -logText "Restart Registry Entry Exists Already" -logFile $logFile
            }

            LogWrite -logText "Restart Required - Restarting..." -logFile $logFile
            Restart-Computer
        }
        default {
            LogWrite -logText "Unsure If A Restart Is Required" -logFile $logFile
            Restart-Computer
            break
        }
    }
}

function Check-WindowsUpdates()
{
    param (
        [string] $logFile
    )

    LogWrite -logText "Checking For Windows Updates" -logFile $logFile
    $Username = $env:USERDOMAIN + "\" + $env:USERNAME

    New-EventLog -Source $ScriptName -LogName 'Windows Powershell' -ErrorAction SilentlyContinue

    $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()

    Write-EventLog -LogName 'Windows Powershell' -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
    LogWrite -logText $Message  -logFile $logFile

    $script:UpdateSearcher = $script:UpdateSession.CreateUpdateSearcher()
    $script:successful = $FALSE
    $script:attempts = 0
    $script:maxAttempts = 12
    while(-not $script:successful -and $script:attempts -lt $script:maxAttempts)
    {
        try
        {
            $script:SearchResult = $script:UpdateSearcher.Search("IsAssigned=1 and IsInstalled=0 and Type='Software' and IsHidden=0")
            $script:successful = $TRUE
        }
        catch
        {
            LogWrite -logText ($_.Exception.ToString()) -logFile $logFile
            LogWrite -logText "Search call to UpdateSearcher was unsuccessful. Retrying in 10s."  -logFile $logFile
            $script:attempts = $script:attempts + 1
            Start-Sleep -s 10
        }
    }

    if ($script:SearchResult.Updates.Count -ne 0)
    {
        $Message = "There are " + $script:SearchResult.Updates.Count + " more updates."
        LogWrite -logText $Message  -logFile $logFile
        try
        {
            for($i=0; $i -lt $script:SearchResult.Updates.Count; $i++)
            {
                LogWrite -logText script:SearchResult.Updates.Item($i).Title -logFile $logFile
                LogWrite -logText $script:SearchResult.Updates.Item($i).Description -logFile $logFile
                LogWrite -logText $script:SearchResult.Updates.Item($i).RebootRequired -logFile $logFile
                LogWrite -logText $script:SearchResult.Updates.Item($i).EulaAccepted -logFile $logFile
            }

            $global:MoreUpdates=1
        }
        catch
        {
            LogWrite -logText ($_.Exception.ToString()) -logFile $logFile
            LogWrite -logText "Showing SearchResult was unsuccessful. Rebooting." -logFile $logFile
            $global:RestartRequired=1
            $global:MoreUpdates=0
            Check-ContinueRestartOrEnd -logFile $logFile
            LogWrite -logText "Show never happen to see this text!" -logFile $logFile
            Restart-Computer
        }
    }
    else
    {
        LogWrite -logText 'There are no applicable updates' -logFile $logFile
        $global:RestartRequired=0
        $global:MoreUpdates=0
    }
}

function EnableWinRm
{
    param (
        [string] $logFile
    )

    $result = New-ScheduledTask -taskName 'EnableWinRm' -application 'sc.exe' -arguments 'config winrm start= auto' -logFile $logFile
    if (-not $result)
    {
        # try doing it without elevation
        LogWrite -logText "Setting the WinRM service to start automatically ..." -logFile $logFile
        & sc.exe config winrm start= auto

        if ($LastExitCode -ne 0)
        {
            LogWrite -logText "Failed to set the WinRM service to start automatically!" -logFile $logFile
            throw "Failed to start WinRM."
        }
    }

    LogWrite -logText "Starting the WinRM service ..." -logFile $logFile
    Start-Service winrm -ErrorAction Stop
}

function Install-WindowsUpdates()
{
    param (
        [string] $logFile
    )

    $script:Cycles++
    LogWrite -logText "Evaluating Available Updates with limit of $($MaxUpdatesPerCycle):" -logFile $logFile
    $UpdatesToDownload = New-Object -ComObject 'Microsoft.Update.UpdateColl'
    $script:i = 0;
    $CurrentUpdates = $script:SearchResult.Updates
    while($script:i -lt $CurrentUpdates.Count -and $script:CycleUpdateCount -lt $MaxUpdatesPerCycle)
    {
        $Update = $CurrentUpdates.Item($script:i)
        if (($Update -ne $null) -and (!$Update.IsDownloaded))
        {
            [bool]$addThisUpdate = $false
            if ($Update.InstallationBehavior.CanRequestUserInput)
            {
                LogWrite -logText "> Skipping: $($Update.Title) because it requires user input" -logFile $logFile
            }
            else
            {
                if (!($Update.EulaAccepted))
                {
                    LogWrite -logText "> Note: $($Update.Title) has a license agreement that must be accepted. Accepting the license." -logFile $logFile
                    $Update.AcceptEula()
                    [bool]$addThisUpdate = $true
                    $script:CycleUpdateCount++
                }
                else
                {
                    [bool]$addThisUpdate = $true
                    $script:CycleUpdateCount++
                }
            }

            if ([bool]$addThisUpdate)
            {
                LogWrite -logText "Adding: $($Update.Title)" -logFile $logFile
                $UpdatesToDownload.Add($Update) |Out-Null
            }
        }

        $script:i++
    }

    if ($UpdatesToDownload.Count -eq 0)
    {
        LogWrite -logText "No Updates To Download..." -logFile $logFile
    }
    else
    {
        LogWrite -logText 'Downloading Updates...' -logFile $logFile
        $ok = 0;
        while (! $ok)
        {
            try
            {
                LogWrite -logText 'Starting download...' -logFile $logFile
                $Downloader = $UpdateSession.CreateUpdateDownloader()
                $Downloader.Updates = $UpdatesToDownload
                $Downloader.Download()
                $ok = 1;
            }
            catch
            {
                LogWrite -logText ($_.Exception.ToString()) -logFile $logFile
                LogWrite -logText "Error downloading updates. Retrying in 30s." -logFile $logFile
                $script:attempts = $script:attempts + 1
                Start-Sleep -s 30
            }
        }

        LogWrite -logText 'Finished Downloading Updates...' -logFile $logFile
    }

    $UpdatesToInstall = New-Object -ComObject 'Microsoft.Update.UpdateColl'
    [bool]$rebootMayBeRequired = $false
    LogWrite -logText 'The following updates are downloaded and ready to be installed:' -logFile $logFile
    foreach ($Update in $script:SearchResult.Updates)
    {
        if (($Update.IsDownloaded))
        {
            LogWrite -logText "> $($Update.Title)" -logFile $logFile
            $UpdatesToInstall.Add($Update) |Out-Null

            if ($Update.InstallationBehavior.RebootBehavior -gt 0)
            {
                [bool]$rebootMayBeRequired = $true
            }
        }
    }

    if ($UpdatesToInstall.Count -eq 0)
    {
        LogWrite -logText 'No updates available to install...' -logFile $logFile
        $global:MoreUpdates=0
    }

    if ($rebootMayBeRequired)
    {
        LogWrite -logText 'These updates may require a reboot' -logFile $logFile
        $global:RestartRequired=1
    }

    if ($UpdatesToInstall.Count -gt 0)
    {
        LogWrite -logText 'Installing updates...' -logFile $logFile

        $Installer = $script:UpdateSession.CreateUpdateInstaller()
        $Installer.Updates = $UpdatesToInstall
        $InstallationResult = $Installer.Install()

        LogWrite -logText "Installation Result: $($InstallationResult.ResultCode)" -logFile $logFile
        LogWrite -logText "Reboot Required: $($InstallationResult.RebootRequired)" -logFile $logFile
        LogWrite -logText 'Listing of updates installed and individual installation results:' -logFile $logFile
        if ($InstallationResult.RebootRequired)
        {
            $global:RestartRequired=1
        }

        for ($i=0; $i -lt $UpdatesToInstall.Count; $i++)
        {
            New-Object -TypeName PSObject -Property @{
                Title = $UpdatesToInstall.Item($i).Title
                Result = $InstallationResult.GetUpdateResult($i).ResultCode
            }

            LogWrite -logText "Item: $($UpdatesToInstall.Item($i).Title))" -logFile $logFile
            LogWrite -logText "Result: $($InstallationResult.GetUpdateResult($i).ResultCode))" -logFile $logFile
        }
    }

    Check-ContinueRestartOrEnd -logFile $logFile
}

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

function New-ScheduledTask
{
    param(
        [string] $taskName,
        [string] $application,
        [string] $arguments,
        [string] $logFile
    )

    . (Join-Path $PSScriptRoot 'variables.ps1')

    $username = $unattendUsername

    $password = ''
    if (($unattendPassword -ne $null) -and ($unattendPassword -ne ''))
    {
        $password = $unattendPassword
    }

    # Try to get the Schedule.Service object. If it fails, we are probably
    # on an older version of Windows. On old versions, we can just execute
    # directly since priv. escalation isn't a thing.
    $schedule = $null
    try
    {
        $schedule = New-Object -ComObject 'Schedule.Service'
    }
    catch [System.Management.Automation.PSArgumentException]
    {
        LogWrite -logText 'Failed get the Schedule.Service COM object' -logFile $logFile
        return $false
    }

    $task_name = "$($taskName)_Elevated_Shell"
    $out_file = "$env:SystemRoot\Temp\WinRM_Elevated_Shell.log"

    if (Test-Path $out_file)
    {
        Remove-Item -Path $out_file -Force | Out-Null
    }

$task_xml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Principals>
    <Principal id="Author">
      <UserId>{username}</UserId>
      <LogonType>Password</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>{execution_time_limit}</ExecutionTimeLimit>
    <Priority>4</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>{command}</Command>
      <Arguments>{arguments}</Arguments>
    </Exec>
  </Actions>
</Task>
'@

    $task_xml = $task_xml.Replace("{command}", $application)
    $task_xml = $task_xml.Replace("{arguments}", $arguments)
    $task_xml = $task_xml.Replace("{username}", $username)
    $task_xml = $task_xml.Replace("{execution_time_limit}", "PT5M")

    $schedule.Connect()
    $task = $schedule.NewTask($null)
    $task.XmlText = $task_xml
    $folder = $schedule.GetFolder("\")
    $folder.RegisterTaskDefinition($task_name, $task, 6, $username, $password, 1, $null) | Out-Null

    $registered_task = $folder.GetTask("\$task_name")
    $registered_task.Run($null) | Out-Null

    $timeout = 10
    $sec = 0
    while ( (!($registered_task.state -eq 4)) -and ($sec -lt $timeout) )
    {
        Start-Sleep -s 1
        $sec++
    }

    if ($timeout -lt $sec)
    {
        LogWrite -logText "Schedule task $($taskName) timed out" -logFile $logFile
        return $false
    }
    else
    {
        LogWrite -logText "Schedule task $($taskName) is running ..." -logFile $logFile
    }

    $cur_line = 0
    do
    {
        Start-Sleep -m 100
        $cur_line = SlurpOutput $out_file $cur_line
    }
    while (!($registered_task.state -eq 3))

    $exit_code = $registered_task.LastTaskResult
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($schedule) | Out-Null

    $output = & cmd /c schtasks.exe /delete /TN "$task_name" /f
    LogWrite -logText $outpout -logFile $logFile
    LogWrite -logText "Removed scheduled task $($taskName)" -logFile $logFile
    return $true
}

function SlurpOutput($out_file, $cur_line)
{
    if (Test-Path $out_file)
    {
        get-content $out_file | select -skip $cur_line | ForEach {
            $cur_line += 1
            Write-Output "$_"
        }
    }

    return $cur_line
}

# --------------- END SCRIPT FUNCTIONS ---------------------------------

"Starting $($MyInvocation.MyCommand.Name)" | Out-File -Filepath "$($env:TEMP)\BoxImageCreation_$($MyInvocation.MyCommand.Name).started.txt" -Append

$logPath = "$env:TEMP\\win-updates.log"

if ($SkipWindowsUpdates)
{
    Write-Output "Skipping windows updates"
    EnableWinRm -logFile $logFile
    exit 0
}

$script:ScriptName = $MyInvocation.MyCommand.ToString()
$script:ScriptPath = $MyInvocation.MyCommand.Path
$script:UpdateSession = New-Object -ComObject 'Microsoft.Update.Session'
$script:UpdateSession.ClientApplicationID = 'Packer Windows Update Installer'

if ($proxyServerAddress)
{
    $script:WebProxy = New-Object -ComObject 'Microsoft.Update.WebProxy'
    $script:WebProxyBypass = New-Object -ComObject 'Microsoft.Update.StringColl'
    $script:WebProxyBypass.Add("*.localtest.me")
    $script:WebProxy.AutoDetect = $false
    $script:WebProxy.Address = $proxyServerAddress
    if ($proxyServerUsername)
    {
        $script:WebProxy.Username = $proxyServerUsername
    }

    if ($proxyServerPassword)
    {
        $script:WebProxy.SetPassword($proxyServerPassword)
    }

    $script:WebProxy.BypassProxyOnLocal = $true
    $script:WebProxy.BypassList = $script:WebProxyBypass
    $script:UpdateSession.WebProxy = $script:WebProxy
}

$script:UpdateSearcher = $script:UpdateSession.CreateUpdateSearcher()
$script:SearchResult = New-Object -ComObject 'Microsoft.Update.UpdateColl'
$script:Cycles = 0
$script:CycleUpdateCount = 0

EnableWinRm -logFile $logPath
Check-WindowsUpdates -logFile $logPath
if ($global:MoreUpdates -eq 1)
{
    Install-WindowsUpdates -logFile $logPath
}
else
{
    Check-ContinueRestartOrEnd -logFile $logPath
}
