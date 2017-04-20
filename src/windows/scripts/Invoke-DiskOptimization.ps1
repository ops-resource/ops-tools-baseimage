$ProgressPreference="SilentlyContinue"

# NOTE: this script should not log anything to disk because it is in charge of optimizing the
#       disk just after defragmentation and prior to empty space zero-ing. Writing log files here defeats the purpose!

Write-Output "Starting $($MyInvocation.MyCommand.Name)"


Optimize-Volume -DriveLetter $($env:SystemDrive)[0] -Verbose
