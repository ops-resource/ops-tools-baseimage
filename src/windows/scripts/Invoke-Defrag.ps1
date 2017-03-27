$ProgressPreference="SilentlyContinue"

# NOTE: this script should not log anything to disk because it will be in charge of defragmentation
#       just prior to zero-ing of the disk space. Writing log files here defeats the purpose!

$filePath = "$($env:TEMP)\$($MyInvocation.MyCommand.Name).started.txt"
Write-Output "Starting $($MyInvocation.MyCommand.Name)"

if (Test-Path 'e:\udefrag.exe')
{
    $scriptPath = 'e:\udefrag.exe'
}
else
{
    $scriptPath = 'f:\udefrag.exe'
}

Write-Output "Starting udefrag from: $($scriptPath)"
& "$scriptPath" --optimize --repeat $($env:SystemDrive)

Write-Output "udefrag completed with exit code: $($LASTEXITCODE)"
