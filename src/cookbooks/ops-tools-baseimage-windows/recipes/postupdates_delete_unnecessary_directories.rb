powershell_script 'remove unnecesary directories' do
  code <<-POWERSHELL
  @(
      "C:\\Recovery",
      "$env:localappdata\\Nuget",
      "$env:localappdata\\temp\\*",
      "$env:windir\\logs",
      "$env:windir\\winsxs\\manifestcache"
  ) | Foreach-Object {
          if (Test-Path $_)
          {
              Write-Host "Removing $_"
              try
              {
                  Takeown /d Y /R /f $_
                  Icacls $_ /GRANT:r administrators:F /T /c /q  2>&1 | Out-Null
                  Remove-Item $_ -Recurse -Force | Out-Null
              }
              catch
              {
                  $global:error.RemoveAt(0)
              }
          }
      }
  POWERSHELL
end
