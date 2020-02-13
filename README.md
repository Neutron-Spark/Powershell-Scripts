# Powershell Scripts
Created Powershell Scripts to perform mundane or specific tasks. These are a mixture of my own and ones that I've stumbled upon in the past but can't find the original poster any more.

Each script folder has it's own README file which describes what the code does and how to run it. Some of these are deprecated due to changes in security (in the case of Office 365 code) or updates.

These scripts were written over a number of years so please excuse the versioning as it's only recently that I've decided to add these to my own GitHub.

# One Liners
Some PowerShell I've used in the past isn't worthy of a full folder, often because they are single lines of PowerShell I stuck in a OneNote. These scraps of PowerShell are here:


## Extract and run all MSIs in a folder
``` powershell
Get-ChildItem "FOLDER_PATH_HERE"  | ForEach-Object { Start-Process FOLDER_PATH_HERE\$_ -ArgumentList "/s /x /b""EXTRACTED_LOCATION"" /v""/qn""" }

Get-ChildItem "EXTRACTED_LOCATION" | ForEach {Start-Process "EXTRACTED_LOCATION\$_" -ArgumentList "/qb" -Wait}
```

So a full example would be:
``` powershell
Get-ChildItem " C:\Extracted\SomeProgram"  | ForEach-Object { Start-Process C:\Extracted\SomeProgram\$_ -ArgumentList "/s /x /b""C:\Extracted"" /v""/qn""" }
Get-ChildItem "C:\Extracted" | ForEach {Start-Process "C:\Extracted\$_" -ArgumentList "/qb" -Wait}
```

## Add to a log file
Adds to log file $Log and displays the text on the screen as well
``` powershell
Add-Content $Log -Value "$(Get-Date -Format G) Log entry here" -PassThru
```
## Get all enabled users Names, Titles and Email addresses exported to a CSV
``` powershell
Get-ADUser -Filter 'enabled -eq $true' -Properties * | ?{$_.distinguishedname -notlike '*Servers*'} | Select cn,sAMAccountName,mail,title,@{n='ParentContainer';e={$_.distinguishedname -replace '^.+?,(CN|OU.+)','$1'}} |  Export-Csv C:\AdExport.csv
```

## Send Email via local SMTP server/relay
The first example sends an email to 'EMAIL_ADDRESS'. `$Body` is specified elsewhere. Calling the function has a default value or can be set to 'Success' or 'Failure' with a reason for each. Example:
```powershell
SendEmail Success "Success reason here"

SendEmail Failure "Failure reason here with variable $Var"

SendEmail
```

The second example sends emails to multiple users. $Body is pulled from the $Log file, comparing the date in the log file to the current date and only retrieving the items found which match the date the script is run. Each line in the log file that matches the date is appended with a `<br>` at the end to show them line by line, as Emails are formatted in HTML. 

Note - The body will only contain lines that have a date prefixed at the front of it.

### Example 1:
```powershell
function SendEmail ($SendStatus, $Reason = "No Reason Given") {
    $smtp = "SMTP_SERVER"
    $to = "DESTINATION_ADDRESS"
    $from = "FROM_ADDRESS"
    switch ($SendStatus) {
        "Success" {$subject = "$(Get-Date -Format G) $Jobname Success - $Reason"}
        "Failure" {$subject = "$(Get-Date -Format G) $Jobname Failure - $Reason"}
        default {$subject = "$(Get-Date -Format G) $Jobname - Unknown failure or incorrect success"}
    }
    send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml
}
```

### Example 2:
```powershell
function SendEmail ($SendStatus, $Reason = "No Reason Given") {
    $smtp = "SMTP_SERVER"
    $to = "DESTINATION_ADDRESS1","DESTINATION_ADDRESS2"
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
```

## Get Running services
Note: This retrieves a list of running services and their startup type along with the account name the user is set to start under
``` powershell
Get-WmiObject win32_service | Where {$_.Started -eq "True"} | Select Name,StartMode,StartName
```

## Connect to a specific customers PowerShell instance
Note: This requires Delegate access to the customers area. Note the configuration name in this case is specified to point at the exchange environment. 
``` powershell
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid?DelegatedOrg=CUSTOMERNAME.onmicrosoft.com -Credential $UserCredential -Authentication Basic -AllowRedirection
Write-Host "Connecting to Server..." -ForegroundColor Yellow

#connect-msolservice $UserCredential
Import-PSSession $Session  -AllowClobber | Out-Null  
```

