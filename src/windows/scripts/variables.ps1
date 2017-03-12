$unattendUsername = '${LocalAdministratorName}'
$unattendPassword = '${LocalAdministratorPassword}'

if ($ENV:UnAttendWindowsUsername) {
    $unattendUsername = $ENV:unattendUsername
}

if ($ENV:UnAttendWindowsPassword) {
    $unattendPassword = $ENV:unattendPassword
}
