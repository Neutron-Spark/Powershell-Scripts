$log = "C:\Windows\Scripts\WSUSMembers.txt"
$Time = Get-Date

Add-Content $log ("Script run on $env:computername`r`nStarted at $Time")

$smtp = "SMTP_SERVER"
$to = "DESITNATION_ADDRESS"
$from = "FROM_ADDRESS"
$body += "Script run on $env:computername`r`nStarted at $Time`r`n"
$subject = "Computer: " + $env:computernameBackup + "Syncing Servers OU with WSUS groups at: $Time"

$Group1 = (Get-ADGroupMember -Identity WSUS_Group1 | Select -Exp name) + (Get-ADGroupMember -Identity WSUS_Group2 | Select -Exp name) | Sort

$AllServers = Get-ADComputer -SearchBase 'OU=Servers,DC=office,DC=company,DC=co,DC=uk' -Filter { (OperatingSystem -Like '*Windows Server*') -And (Name -Like 'BIS-*') -And (enabled -eq "true") } | Select -Exp Name | Sort

$Compare = Compare-Object $AllServers $Group1

$Count = 0

$Compare | ForEach-Object {

    $Time = Get-Date
    if ($_.sideindicator -eq '<='){
        if ($Count -eq 0){
            Add-Content $log ("Adding " + $_.InputObject + " to WSUS group 1 at $Time")
            $body += ("`r`nAdding " + $_.InputObject + " to WSUS group 1 at $Time`r`n")
            Add-ADGroupMember -Identity WSUS_Group1 -Members (Get-ADComputer $_.InputObject)
            $Count++
        }
        elseif ($Count -eq 1){
            Add-Content $log ("Adding " + $_.InputObject + " to WSUS group 2 at $Time")
            $body += ("`r`nAdding " + $_.InputObject + " to WSUS group 2 at $Time`r`n")
            Add-ADGroupMember -Identity WSUS_Group2 -Members (Get-ADComputer $_.InputObject)
            $Count--
        }
    }
    if ($_.sideindicator -eq '=>'){
         Add-Content $log ("Computer: " + $_.InputObject + " is already in a WSUS group, but not in the servers OU, meaning manually added or a DC.")
         $body += ("`r`nComputer: " + $_.InputObject + " is already in a WSUS group, but not in the servers OU, meaning manually added or a DC.`r`n")
    }
}
Add-Content $log ("`r`nCompleted at $Time")
$body += "`r`nCompleted at $Time`r`n"
Add-Content $log ("Excluded filter: OperatingSystem -Like '*Windows Server*', Name -Like 'BIS-*', enabled -eq true`r`n")
$body += "Excluded filter: OperatingSystem -Like '*Windows Server*', Name -Like 'BIS-*', enabled -eq true`r`n"
$body += "`r`nLog location: " + $log

send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body $body 