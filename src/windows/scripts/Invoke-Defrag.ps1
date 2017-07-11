$ProgressPreference="SilentlyContinue"

# NOTE: this script should not log anything to disk because it will be in charge of defragmentation
#       just prior to zero-ing of the disk space. Writing log files here defeats the purpose!

# -------------------------- Script functions --------------------------------

function Find-FilePathOnDvd
{
    [CmdletBinding()]
    param(
        [string] $fileName
    )

    $ErrorActionPreference = 'Stop'

    try
    {
        $drives = Get-WMIObject -Class Win32_CDROMDrive -ErrorAction Stop
        foreach($drive in $drives)
        {
            $path = Join-Path $drive.Drive $fileName
            if (Test-Path $path)
            {
                return $path
            }
        }
    }
    catch
    {
        Continue;
    }

    return ''
}

# -------------------------- Script start ------------------------------------

Write-Output "Starting $($MyInvocation.MyCommand.Name)"

$scriptPath = Find-FilePathOnDvd -fileName 'udefrag.exe'

Write-Output "Starting udefrag from: $($scriptPath)"
& "$scriptPath" --optimize --repeat $($env:SystemDrive)

Write-Output "udefrag completed with exit code: $($LASTEXITCODE)"
