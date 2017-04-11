rem Delete all the unattend install / panther / sysprep files
rmdir /Q /S %systemroot%\windows\system32\sysprep\panther
del /Q /F %systemroot%\windows\system32\sysprep\unattend.xml

rmdir /Q /S %systemroot%\windows\panther

rem Nuke the temp directories
rmdir /Q /S %systemroot%\windows\Temp

rem Finally delete the currently running script, we don't need it anymore
del /F /Q %systemroot%\windows\setup\scripts\SetUpComplete.cmd
