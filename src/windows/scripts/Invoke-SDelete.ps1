$scriptPath = Join-Path $PSScriptRoot 'sdelete.exe'
&"$scriptPath" -accepteula -z $($env:SystemDrive)
