##### Script Information Here! #####
$JobName = "Backup-Folders"
$Log = "C:\Scripts\$JobName-RunLog.txt"
#Version = 1.0
#Author = Tom Bestow
#Purpose = Backup folders to a remote location
##### -------------------- #####

##### Functions Here #####
function SendEmail ($SendStatus, $Reason = "No Reason Given") {
    $smtp = "<SMTP SERVER HERE>"
    $to = "<TO EMAIL ADDRESS>"
    $from = "$JobName@<DOMAIN>"
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

##### Script Variables Here #####
$Source = 'C:\Temp'
$DestinationPath = 'C:\NewTemp'
##### -------------------- #####

##### Script Here #####
Add-Content $Log -Value "$(Get-Date -Format G) Job Started on $Env:ComputerName" -PassThru
$StartTime = Get-Date -Format G

ForEach ($SourcePath in $Source) {
    Add-Content $Log -Value "$(Get-Date -Format G) Backup Source: $SourcePath, Backup Destination: $DestinationPath" -PassThru

    Add-Content $Log -Value "$(Get-Date -Format G) Testing $SourcePath exists" -PassThru
    if (Test-Path $SourcePath) {

        Add-Content $Log -Value "$(Get-Date -Format G) Folder exists, proceeding" -PassThru

        Add-Content $Log -Value "$(Get-Date -Format G) Testing $DestinationPath exists and can be connected to" -PassThru
        if (Test-Path $DestinationPath) {
            Add-Content $Log -Value "$(Get-Date -Format G) Folder exists, proceeding" -PassThru
            robocopy $SourcePath ($DestinationPath+"\"+$(Split-Path $SourcePath -Leaf)) /e /mir /r:10 /log+:C:\Scripts\RobocopyLog.txt
            if ($LASTEXITCODE -lt 2) {
                Add-Content $Log -Value "$(Get-Date -Format G) Copyjob passed" -PassThru
            } else {
                Add-Content $Log -Value "$(Get-Date -Format G) Copyjob failed with Exit Code $LASTEXITCODE" -PassThru
                SendEmail Failure "Copyjob failed with Exit Code $LASTEXITCODE"
                Exit
            }
        } else {
            Add-Content $Log -Value "$(Get-Date -Format G) $DestinationPath doesn't exist or cannot be connected to. Backup Failed" -PassThru
            SendEmail Failure "$DestinationPath doesn't exist or can't be connected to"
            Exit
        }
    } else {
        Add-Content $Log -Value "$(Get-Date -Format G) $SourcePath doesn't exist. Backup Failed" -PassThru
        SendEmail Failure "$SourcePath doesn't exist"
        Exit
    }
}
$EndTime = Get-Date -Format G
Add-Content $Log -Value "$(Get-Date -Format G) Job Started: $StartTime, Job Finished: $EndTime" -PassThru
##### -------------------- #####