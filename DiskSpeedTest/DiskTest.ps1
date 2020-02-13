$JobName = "Disk Test"
if (Test-Path "C:\Scripts\$JobName\Log.txt") {
    $Log = "C:\Scripts\$JobName\Log.txt"
}
else {
    New-Item "C:\Scripts\$JobName\" -type directory
    New-Item "C:\Scripts\$JobName\Log.txt" -type file
    $Log = "C:\Scripts\$JobName\Log.txt"
}

function SendEmail ($SendStatus, $Reason = "No Reason Given") {
    $smtp = "SMTP_SERVER"
    $to = "DESITNATION_ADDRESS"
    $from = "FROM_ADDRESS"
    switch ($SendStatus) {
        "Success" {$subject = "$(Get-Date -Format G) $Jobname Success - $Reason"}
        "Failure" {$subject = "$(Get-Date -Format G) $Jobname Failure - $Reason"}
        default {$subject = "$(Get-Date -Format G) $Jobname - Unknown failure or incorrect success"}
    }
    send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body -BodyAsHtml
}

Add-Content $Log -Value "------------------------------------------------------------------------------------" -PassThru
Add-Content $Log -Value "$(Get-Date -Format G) Starting $JobName" -PassThru

$Date = Get-Date -Format dd-MM-yyyy

Add-Content $Log -Value "$(Get-Date -Format G) Starting Disk Benchmark" -PassThru
C:\Scripts\diskspd.exe -W -d60 -h -w50 -t1 -o32 C:\Scripts\TestFile.dat | Out-File "C:\Scripts\$JobName\$Date.txt" -ErrorAction SilentlyContinue

If (Test-Path "C:\Scripts\$JobName\$Date.txt") {
    $Results = Get-Content "C:\Scripts\$JobName\$Date.txt" | Select-String -Pattern "total:" | Out-String
    $Results = $Results.Replace("total:","").Replace("`t","").Replace(" ","").Replace("`n","")
    $Results_TotalBytes, $Results_TotalIO, $Results_TotalMBs, $Results_TotalIOs, 
    $Results_ReadBytes, $Results_ReadIO, $Results_ReadMBs, $Results_ReadIOs,
    $Results_WriteBytes, $Results_WriteBytes, $Results_WriteMBs, $Results_WriteIOs = $Results.Split("|")

    $Results_TotalIOs = $Results_TotalIOs.Split("`n")[0]
}
else {
    Add-Content $Log -Value "$(Get-Date -Format G) Testing failed for some reason, no results file generated. Exiting." -PassThru
    Exit
}

$ResultsRecord = "C:\Scripts\$JobName\ResultsRecord.txt"
$Average = $null
[int]$Variance = -50

If (Test-Path $ResultsRecord) {
    Get-Content $ResultsRecord | ForEach-Object {
        if ($_ -ne $null) {
            [int]$Average += $_
        }
    }
    $Average = $Average/$((Get-Content $ResultsRecord | Where-Object {$_ -gt 0}).Count)
    Add-Content $Log -Value "$(Get-Date -Format G) Average past throughput is $Average MB/s" -PassThru
    Add-Content $Log -Value "$(Get-Date -Format G) Latest result is $Results_TotalMBs MB/s" -PassThru
    $PercDiff = (($Results_TotalMBs - $Average)/$Results_TotalMBs).ToString("P")
    [int]$Diff = (($Results_TotalMBs - $Average)/$Results_TotalMBs)*100
    if ($Diff -ge 0) {
        Add-Content $Log -Value "$(Get-Date -Format G) $PercDiff increase in speed" -PassThru
    }
    else {
        Add-Content $Log -Value "$(Get-Date -Format G) $PercDiff decrease in speed" -PassThru
        If ($Diff -lt $Variance) {
             Add-Content $Log -Value "$(Get-Date -Format G) WARNING - MASSIVE DECREASE IN THROUGHPUT" -PassThru
             $body = @()
             $Time = Get-Date -Format d
             Add-Content $Log -Value "$(Get-Date -Format G) Sending Email...." -PassThru
             $body = (Get-Content $Log | Select-String -pattern $Time) -join '<br>'

             SendEmail Failure "Massive decrease in throughput on $Env:COMPUTERNAME"
        }
    }
    Add-Content $Log -Value "$(Get-Date -Format G) Adding results to results file for more resulting results" -PassThru
    Add-Content $ResultsRecord -Value "$Results_TotalMBs`n"
}
else {
    Add-Content $Log -Value "$(Get-Date -Format G) Results file missing, generating new one and adding results to it. Averaging will not be calculated" -PassThru
    New-Item $ResultsRecord -type file
    Add-Content $ResultsRecord -Value "$Results_TotalMBs`n"
}

$DaysToKeep = "-30"
Add-Content $Log -Value "$(Get-Date -Format G) Removing files older than $DaysToKeep..." -PassThru

Get-ChildItem -Path "C:\Scripts\$JobName" -Recurse -Filter "*.txt" -Exclude "Config.txt","*.ps1",$ResultsRecord | ForEach {
    if ($_.LastWriteTime -lt (Get-Date).AddDays($DaysToKeep)) {
        Add-Content $Log -Value "$(Get-Date -Format G) Removing Item $_ due to deletion policy" -PassThru
        Remove-Item -Path $_.FullName
    }
}

Add-Content $Log -Value "$(Get-Date -Format G) Script Complete" -PassThru