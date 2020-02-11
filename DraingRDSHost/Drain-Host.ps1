##### Script Information Here! #####
$JobName = "Drain RDS Session Host"
$Log = "C:\Scheduledtasks\$JobName-Log.txt"
#Version = 1.0
#Author = Tom Bestow
#Purpose = Drains host 04 if it's currently accepting new connections.
##### -------------------- #####
Add-Content $Log -Value "$(Get-Date -Format G) Starting Script." -PassThru

$ActiveServer = Get-RDConnectionBrokerHighAvailability

if ($ActiveServer) {
    $HostnameFQDN = [System.Net.Dns]::GetHostByName((hostname)).HostName

    if ($ActiveServer.ActiveManagementServer -eq $HostnameFQDN) {
        Add-Content $Log -Value "$(Get-Date -Format G) $HostnameFQDN is the active connection broker" -PassThru

        $RDSSessionHost = Get-RDSessionHost -CollectionName "<COLLECTION NAME>" | Where {$_.SessionHost -EQ "<SESSION HOST>"}

        if ($RDSSessionHost.NewConnectionAllowed -eq "Yes") {
            Add-Content $Log -Value "$(Get-Date -Format G) $($RDSSessionHost.SessionHost) is accepting new connections, setting host to drain." -PassThru
            Set-RDSessionHost -SessionHost $RDSSessionHost.SessionHost -NewConnectionAllowed NotUntilReboot 
        } else {
            Add-Content $Log -Value "$(Get-Date -Format G) $($RDSSessionHost.SessionHost) is not accepting new connections. Presuming that this is intentional and exiting the script" -PassThru
        }
    } else {
        Add-Content $Log -Value "$(Get-Date -Format G) The script this was run on is not the active connection broker. Script Stopping." -PassThru
    }
} else {
    Add-Content $Log -Value "$(Get-Date -Format G) The command Get-RDConnectionBrokerHighAvailability returned null or an Error"
}
Add-Content $Log -Value "$(Get-Date -Format G) Stopping Script" -PassThru