<#
    .SYNOPSIS

    Enables the 'unsafe' connection mode for WinRM by enabling basic authentication and unencrypted connections.


    .DESCRIPTION

    The Set-UnsafeConnectionModeForWinRm script enables the 'unsafe' connection mode for WinRM by enabling basic
    authentication and unencrypted connections. This is required for Packer because currently the Go WinRM
    library cannot authenticate via NTLM (see here: http://www.hurryupandwait.io/blog/creating-a-windows-server-2016-vagrant-box-with-chef-and-packer).

    Disabling these 'unsafe' settings is normally done through a BAT file dropped in the 'c:\windows\Panther'
    directory. This reset script is executed prior to executing sysprep.

    NOTE: It is important to disable these settings once the configuration via Packer is done. It is unsafe
    to leave these settings on a base image!
#>
[CmdletBinding()]
param()

$ProgressPreference="SilentlyContinue"

netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
