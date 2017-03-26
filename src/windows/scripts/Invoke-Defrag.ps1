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

if (Test-Path 'e:\udefrag.exe')
{
    $scriptPath = 'e:\udefrag.exe'
}
else
{
    $scriptPath = 'f:\udefrag.exe'
}

LogWrite -logFile $filePath -logText "Starting udefrag from: $($scriptPath)"
& "$scriptPath" --optimize --repeat $($env:SystemDrive)

LogWrite -logFile $filePath -logText "udefrag completed with exit code: $($LASTEXITCODE)"
