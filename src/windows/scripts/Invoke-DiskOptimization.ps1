$ProgressPreference="SilentlyContinue"

Optimize-Volume -DriveLetter $($env:SystemDrive)[0] -Verbose
