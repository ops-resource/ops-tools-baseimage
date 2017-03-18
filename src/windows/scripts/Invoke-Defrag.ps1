$ProgressPreference="SilentlyContinue"


if (Test-Path 'e:\udefrag.exe')
{
    $scriptPath = 'e:\udefrag.exe'
}
else
{
    $scriptPath = 'f:\udefrag.exe'
}

&"$scriptPath" --optimize --repeat $($env:SystemDrive)
