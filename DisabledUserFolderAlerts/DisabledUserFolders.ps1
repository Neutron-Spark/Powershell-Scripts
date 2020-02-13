##### Script Information Here! #####
$JobName = "Disabled User Folder Alert"
$Log = "C:\Windows\Scripts\$JobName-Log.txt"
#Version = 1.0
#Author = Tom Bestow
#Purpose = Find disabled users folders in the user folder directory and alerts the admin to them needing to be deleted.
##### -------------------- #####

##### Functions Here #####
function SendEmail ($SendStatus, $Reason = "No Reason Given") {
    $smtp = "SMTP_SERVER"
    $to = "DESITNATION_ADDRESS"
    $from = "FROM_ADDRESS"
    switch ($SendStatus) {
        "Success" {$subject = "$(Get-Date -Format G) $Jobname Success - $Reason"}
        "Failure" {$subject = "$(Get-Date -Format G) $Jobname Failure - $Reason"}
        default {$subject = "$(Get-Date -Format G) $Jobname - Unknown failure or incorrect success"}
    }
    $body = "<font face=""Microsoft Sans Serif"" size=""2""><b>$JobName</b><br>$(Get-Date -Format G)<br> Run on $env:COMPUTERNAME<br><br>"
    $Time = Get-Date -Format d
    $body += (Get-Content $Log | Select-String -pattern $Time) -join '<br>'
    send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml
}
##### -------------------- #####

Add-Content $Log -Value "$(Get-Date -Format G) Script started. Adding AD module...." -PassThru
##### Import Modules Here #####
try {
    Import-Module ActiveDirectory
}
catch {
    Add-Content $Log -Value "$(Get-Date -Format G) Error Loading AD module. $_" -PassThru
    Add-Content $Log -Value "$(Get-Date -Format G) Exiting" -PassThru
    SendEmail Failure -Reason $_
    Exit
}
##### -------------------- #####


##### Script Variables Here #####
$FoldersToBeDeleted = @()
[int] $TotalSize = 0
[int] $Count = 0
##### -------------------- #####

##### Script Here #####
Add-Content $Log -Value "$(Get-Date -Format G) Generating list of disabled users and comparing to user folders..." -PassThru 
$DisabledUsers = Search-ADAccount -AccountDisabled -UsersOnly | Select SamAccountName
Add-Content $Log -Value "$(Get-Date -Format G) Users that are disabled and that have a folder in \Users" -PassThru
foreach ($User in $DisabledUsers) {
    if (Test-Path "PATH_TO_USER_DIRECTORY\$($User.SamAccountName)") {
        [int]$Size = ((Get-ChildItem "PATH_TO_USER_DIRECTORY\$($User.SamAccountName)" -Recurse | Measure-Object -Property length -Sum).Sum)/1MB
        Add-Content $Log -Value "$(Get-Date -Format G) $($User.SamAccountName), Size: $Size MB" -PassThru
        $Count++ 
        $TotalSize += $Size
    }
}
Add-Content $Log -Value "`n$(Get-Date -Format G) Total size = $TotalSize MB" -PassThru

SendEmail Success "$Count disabled users with folders still totalling $TotalSize MB of space"

##### -------------------- #####