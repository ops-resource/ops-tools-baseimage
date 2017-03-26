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

if (Test-Path 'e:\sdelete.exe')
{
    $scriptPath = 'e:\sdelete.exe'
}
else
{
    $scriptPath = 'f:\sdelete.exe'
}

LogWrite -logFile $filePath -logText "Starting sdelete from: $($scriptPath)"
& "$scriptPath" -accepteula -s -z $($env:SystemDrive)

LogWrite -logFile $filePath -logText "sdelete completed with exit code: $($LASTEXITCODE)"
