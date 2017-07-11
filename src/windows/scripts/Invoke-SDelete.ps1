$ProgressPreference="SilentlyContinue"

# NOTE: this script should not log anything to disk because it is in charge of zero-ing out the empty
#       space. Writing to the disk defeats the purpose!

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

$scriptPath = Find-FilePathOnDvd -fileName 'sdelete.exe'

Write-Output "Starting sdelete from: $($scriptPath)"
& "$scriptPath" -accepteula -s -z $($env:SystemDrive)

Write-Output "sdelete completed with exit code: $($LASTEXITCODE)"
