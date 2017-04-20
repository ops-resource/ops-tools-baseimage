$ProgressPreference="SilentlyContinue"

# NOTE: this script should not log anything to disk because it is in charge of zero-ing out the empty
#       space. Writing to the disk defeats the purpose!

Write-Output "Starting $($MyInvocation.MyCommand.Name)"

if (Test-Path 'e:\sdelete.exe')
{
    $scriptPath = 'e:\sdelete.exe'
}
else
{
    $scriptPath = 'f:\sdelete.exe'
}

Write-Output "Starting sdelete from: $($scriptPath)"
& "$scriptPath" -accepteula -s -z $($env:SystemDrive)

Write-Output "sdelete completed with exit code: $($LASTEXITCODE)"
