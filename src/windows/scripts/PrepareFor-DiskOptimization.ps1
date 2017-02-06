<#
    .SYNOPSIS

    Prepares the system drive for optimization.


    .DESCRIPTION

    The PrepareFor-DiskOPtimization script removes deletes unused file and directories and then zeros out the unused disk space.
#>
[CmdletBinding()]
param()


Write-Host "Cleaning Temp Files"
try
{
    $path = 'C:\Windows\Temp\*'
    Takeown /d Y /R /f $path
    Icacls $path /GRANT:r administrators:F /T /c /q  2>&1
    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}
catch
{
    # Don't care if this doesn't work.
}

Write-Host "Optimizing Drive"
Optimize-Volume -DriveLetter C

Write-Host "Wiping empty space on disk..."
$FilePath="c:\zero.tmp"
$Volume = Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'"
$ArraySize= 64kb
$SpaceToLeave= $Volume.Size * 0.05
$FileSize= $Volume.FreeSpace - $SpacetoLeave
$ZeroArray= new-object byte[]($ArraySize)

$Stream= [io.File]::OpenWrite($FilePath)
try
{
   $CurFileSize = 0
    while ($CurFileSize -lt $FileSize)
    {
        $Stream.Write($ZeroArray,0, $ZeroArray.Length)
        $CurFileSize +=$ZeroArray.Length
    }
}
finally
{
    if($Stream)
    {
        $Stream.Close()
    }
}

Remove-Item $FilePath
