@ECHO OFF

SET SCRIPTNAME=%~dp0Invoke-Sysprep.ps1
PowerShell.exe -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Unrestricted -Command "& { $ErrorActionPreference = 'Stop'; & '%SCRIPTNAME%' }"

SET RESULT=%ERRORLEVEL%
ECHO ERRORLEVEL=%RESULT%
EXIT /B %RESULT%
