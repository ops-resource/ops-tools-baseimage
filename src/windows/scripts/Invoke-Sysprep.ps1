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

@('c:\unattend.xml', 'c:\windows\panther\unattend\unattend.xml', 'c:\windows\panther\unattend.xml', 'c:\windows\system32\sysprep\unattend.xml') | Foreach-Object {
    if (test-path $_)
    {
        LogWrite -logFile $filePath -logText "Removing $($_)"
        try
        {
            remove-item $_ > $null
        }
        catch
        {
            LogWrite -logFile $filePath -logText "$($_.Exception.ToString())"
        }
    }
}

$path = 'c:\windows\panther\unattend'
if (!(test-path $path))
{
    LogWrite -logFile $filePath -logText "Creating directory $path"
    try
    {
        New-Item -path $path -type directory > $null
    }
    catch
    {
        LogWrite -logFile $filePath -logText "$($_.Exception.ToString())"
    }
}

if (Test-Path 'e:\sysprep-unattend.xml')
{
    LogWrite -logFile $filePath -logText "Copying e:\sysprep-unattend.xml to c:\windows\panther\unattend\unattend.xml"
    try
    {
        Copy-Item 'e:\sysprep-unattend.xml' 'c:\windows\panther\unattend\unattend.xml' > $null
    }
    catch
    {
        LogWrite -logFile $filePath -logText "$($_.Exception.ToString())"
    }
}
else
{
    LogWrite -logFile $filePath -logText "Copying f:\sysprep-unattend.xml to c:\windows\panther\unattend\unattend.xml"
    try
    {
        Copy-Item 'f:\sysprep-unattend.xml' 'c:\windows\panther\unattend\unattend.xml'> $null
    }
    catch
    {
        LogWrite -logFile $filePath -logText "$($_.Exception.ToString())"
    }
}

# Don't exit during sysprep because Packer doesn't notice that the VM is stopped. So run sysprep, then return an exit code
# which Packer does understand?
$command = '& "c:\windows\system32\sysprep\sysprep.exe" /generalize /oobe /quiet /quit /unattend:"c:\windows\panther\unattend\unattend.xml"'
LogWrite -logFile $filePath -logText "Invoking sysprep with command: $($command)"
Invoke-Expression -Command $command

LogWrite -logFile $filePath -logText "sysprep completed with exit code: $($LASTEXITCODE)"

LogWrite -logFile $filePath -logText "Return exit 0"
exit 0
