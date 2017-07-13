$ProgressPreference="SilentlyContinue"

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

# NOTE: this script should not log anything to disk because the disk should be left in the state that we
#       want to package it in.

Write-Output "Starting $($MyInvocation.MyCommand.Name)"

@('c:\unattend.xml', 'c:\windows\system32\sysprep\unattend.xml') | Foreach-Object {
    if (test-path $_)
    {
        Write-Output "Removing $($_)"
        try
        {
            remove-item $_ -Force -ErrorAction SilentlyContinue
        }
        catch
        {
            Write-Output "$($_.Exception.ToString())"
        }
    }
}

@('c:\windows\panther', 'c:\windows\system32\sysprep\panther') | Foreach-Object {
    if (test-path $_)
    {
        Write-Output "Removing $($_)"
        try
        {
            remove-item $_ -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch
        {
            Write-Output "$($_.Exception.ToString())"
        }
    }
}

$files = @{
    'sysprep-unattend.xml' = 'c:\windows\panther\unattend\unattend.xml';
    'setupcomplete.cmd' = 'c:\windows\Setup\Scripts\setupcomplete.cmd';
}

foreach($item in $files.GetEnumerator())
{
    $fileName = $item.Key
    $target = $item.Value

    $scriptPath = Find-FilePathOnDvd -fileName $fileName
    Write-Output "Copying $scriptPath to $target"
    try
    {
        $path = Split-Path $target -Parent
        if (-not (test-path $path))
        {
            Write-Output "Creating directory $path"
            try
            {
                New-Item -path $path -type directory
            }
            catch
            {
                Write-Output "$($_.Exception.ToString())"
            }
        }

        Copy-Item $scriptPath $target
    }
    catch
    {
        Write-Output "$($_.Exception.ToString())"
    }
}

# Don't exit during sysprep because Packer doesn't notice that the VM is stopped. So run sysprep, then return an exit code
# which Packer does understand?
$command = '& "c:\windows\system32\sysprep\sysprep.exe" /generalize /oobe /quiet /shutdown /unattend:"c:\windows\panther\unattend\unattend.xml"'
Write-Output "Invoking sysprep with command: $($command)"
Invoke-Expression -Command $command

Write-Output "sysprep completed with exit code: $($LASTEXITCODE)"

Write-Output "Return exit 0"
exit 0
