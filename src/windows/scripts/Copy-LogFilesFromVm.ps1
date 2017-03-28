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
    "c:\user\$($userName)\AppData\Local\Temp" = 'user'
}

foreach($path in $pathsToCopy.GetEnumerator())
{
    $destination = Join-Path $targetDirectory $path.Value
    Copy-item -FromSession $session -Path $path.Key -Destination $destination -Verbose
}
