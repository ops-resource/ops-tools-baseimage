rem Delete all the unattend install / panther / sysprep files
rmdir /Q /S %systemroot%\system32\sysprep\panther
del /Q /F %systemroot%\system32\sysprep\unattend.xml

rmdir /Q /S %systemroot%\panther

rem Nuke the temp directories
rmdir /Q /S %systemroot%\Temp

rem Nuke the old administrator account
rem net user ${LocalAdministratorName} /delete
rem rmdir /Q /S c:\Users\${LocalAdministratorName}

rem Finally delete the currently running script, we don't need it anymore
del /F /Q %systemroot%\setup\scripts\SetUpComplete.cmd
