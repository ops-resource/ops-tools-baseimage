$ProgressPreference="SilentlyContinue"

@('c:\unattend.xml', 'c:\windows\panther\unattend\unattend.xml', 'c:\windows\panther\unattend.xml', 'c:\windows\system32\sysprep\unattend.xml') | %{
    if (test-path $_)
    {
        write-host "Removing $($_)"
        remove-item $_ > $null
    }
}

if (!(test-path 'c:\windows\panther\unattend'))
{
    write-host "Creating directory $($_)"
    New-Item -path 'c:\windows\panther\unattend' -type directory > $null
}

if (Test-Path 'e:\sysprep-unattend.xml')
{
    write-host "Copying e:\sysprep-unattend.xml to c:\windows\panther\unattend\unattend.xml"
    Copy-Item 'e:\sysprep-unattend.xml' 'c:\windows\panther\unattend\unattend.xml' > $null
}
else
{
    write-host "Copying f:\sysprep-unattend.xml to c:\windows\panther\unattend\unattend.xml"
    Copy-Item 'f:\sysprep-unattend.xml' 'c:\windows\panther\unattend\unattend.xml'> $null
}

& "c:\windows\system32\sysprep\sysprep.exe" /generalize /oobe /quiet /shutdown /unattend:'c:\windows\panther\unattend\unattend.xml'
