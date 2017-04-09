[CmdletBinding()]
param(
    [string] $vmName,
    [string] $userName,
    [string] $userPassword,
    [string] $targetDirectory
)
$password = ConvertTo-SecureString $userPassword -AsPlainText -Force
$cred = New-object System.Management.Automation.PSCredential $userName, $password
$session = New-PSSession -VMName $vmName -Credential $cred

$pathsToCopy = @{
    'c:\windows\temp' = 'windows'
    "c:\users\$($userName)\AppData\Local\Temp" = 'user'
    "c:\temp" = "root"
    "c:\Windows\System32\Sysprep\Panther" = "sysprep.generalize"
    "c:\Windows\Panther" = "sysprep.specialize"
    "C:\Windows\Panther\UnattendGC" = "windows.unattend"
}

foreach($path in $pathsToCopy.GetEnumerator())
{
    $remoteFiles = Invoke-Command `
        -Session $session `
        -ArgumentList @( $path.Key ) `
        -ScriptBlock {
            param(
                [string] $dir
            )

            Write-Verbose "Searching for files to copy in: $dir"
            return Get-ChildItem -Path $dir -Recurse -Force |
                Where-Object { -not $_.PsIsContainer } |
                Select-Object -ExpandProperty FullName
        }

    Write-Verbose "Copying files from the remote resource: $remoteFiles"

    $localTargetDirectory = Join-Path $targetDirectory $path.Value
    Write-Verbose "Copying files to the local directory at: $localTargetDirectory"
    foreach($fileToCopy in $remoteFiles)
    {
        $relativePath = $fileToCopy.SubString($path.Key.Length )
        $localPath = Join-Path $localTargetDirectory $relativePath

        $localDirectory = Split-Path -Path $localPath -Parent
        if (-not (Test-Path $localDirectory))
        {
            New-Item -Path $localDirectory -ItemType Directory
        }

        Write-Verbose "Copying $fileToCopy to $localPath"
        Copy-item -FromSession $session -Path $fileToCopy -Destination $localPath -Verbose -ErrorAction SilentlyContinue
    }
}
