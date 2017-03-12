$ProgressPreference="SilentlyContinue"

$scriptPath = join-path $PSScriptRoot 'udefrag.exe'
&"$scriptPath" --optimize --repeat $($env:SystemDrive)
