$ProgressPreference="SilentlyContinue"

if (Test-Path 'e:\sdelete.exe')
{
    $scriptPath = 'e:\sdelete.exe'
}
else
{
    $scriptPath = 'f:\sdelete.exe'
}

&"$scriptPath" -accepteula -z $($env:SystemDrive)
