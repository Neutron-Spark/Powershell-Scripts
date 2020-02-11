# Name: OldVMsOnVMWare.ps1
# Author: Tom Bestow
# Version: 1.0
# Date Created: 23/11/2017
# Purpose: This polls all of the powered off Virtual Machines on a VMWare cluster and find their power off time (if stored in the VSphere log) and compiles it into a report
# Notes: Although this gets the power off time for some machines, others are more difficult due to the nature of the way individual VM logs are stored.
# Requirements: An AD Account with Admin permissions for the VSphere cluster
# How to use: OldVMsOnVMWare.ps1 -Server ssplevvc02.silversands.co.uk -Output C:\SomeOtherLocation

param (
    [Parameter(Mandatory=$true)][string]$Server,
    [string]$Output = "C:\Temp"
)

If (Get-Module -ListAvailable -Name VMWare.PowerCLI) {
    Write-Host (Get-Date -Format G) " Importing VMWare PowerCLI addin..."
    Import-Module VMware.PowerCLI
} else {
    Write-Host (Get-Date -Format G) " PowerCLI not installed, would you like to install it? This will prompt for trusting a new powershell library location..."
    $Readhost = Read-Host " ( y / n ) "
    Switch ($Readhost) {
        Y {Write-Host (Get-Date -Format G) " Downloading and installing. You will need to re-run this script afterwards"; Install-Module -Name VMWare.PowerCLI -Scope CurrentUser}
        N {Write-Host (Get-Date -Format G) " Exiting"; Exit}
        Default {Write-Host (Get-Date -Format G) " Incorrect input, Exiting"; Exit} 
    }
}

Write-Host (Get-Date -Format G) " Getting login information"
$UserCredential = Get-Credential

Write-Host (Get-Date -Format G) " Testing Output folder location"
if (Test-Path $Output) {
    Write-Host (Get-Date -Format G) " Path ok!"
} else {
    Write-Host (Get-Date -Format G) " Path not created, you need to create the folder first!"
    Exit
}

try {
    Connect-VIServer -Server $Server -Credential $UserCredential | Out-Null
} catch {
    Write-Host (Get-Date -Format G) " Error $_"
    Write-Host (Get-Date -Format G) " Exiting..."
    Sleep(10)
    Exit
}

$AccountedVMs = @()
$PoweredOffVMs = @()
$RemainingOffVms = @()
$VMResults = @()

Write-Host (Get-Date -Format G) " Connected to $Server, finding list of Powered Off VMs"
$PoweredOffVMs = Get-VM | Where {$_.PowerState -EQ "PoweredOff"}
Write-Host (Get-Date -Format G) " $($PoweredOffVMs.Count) Powered off VMs"


ForEach ($VM in $PoweredOffVMs) {
    $VMEvent = Get-VIEvent -Entity $VM -MaxSamples ([int]::MaxValue) | where {$_ -is [VMware.Vim.VmPoweredOffEvent]} | Sort-Object CreatedTime -Descending | Select CreatedTime,FullFormattedMessage -First 1
    
    If ($VMEvent) {
        $VMCreated = $VMEvent.CreatedTime
        $VMMessage = $VMEvent.FullFormattedMessage
        $VMMessage = $VMMessage.Split(" ") | Select -First 1
        $AccountedVMs += $VM

        $Item = New-Object System.Object
        $Item | Add-Member -Type NoteProperty -Name VM -Value "$VM"
        $Item | Add-Member -Type NoteProperty -Name 'Powered Off MM/DD/YYYY' -Value "$VMCreated"
        $Item | Add-Member -Type NoteProperty -Name Notes -Value "Event was pulled from VSphere event log"
        $Item | Add-Member -Type NoteProperty -Name 'Last log write' -Value "N\A"
        $Item | Add-Member -Type NoteProperty -Name 'Last log entry' -Value "N\A"
        $VMResults += $Item
        Write-Host (Get-Date -Format G) " Processing $VM"
    }
}

ForEach ($POVMs in $PoweredOffVMs) {
    if ($AccountedVMs.Name -notcontains $POVMs.Name) {
        $RemainingOffVms += $POVMs
    }
}

Write-Host (Get-Date -Format G) " $($AccountedVMs.Count) VMs found in VSphere Event logs, $($RemainingOffVms.Count) Remaining"
Write-Host (Get-Date -Format G) " Remaining VMs will have their logs trawled. This will take time."

ForEach ($VM in $RemainingOffVms) {
    $ErrorOccured = $false
    $Counter++
    try {
        $DatatStoreVM = Get-VM $VM | Get-Datastore
    } catch {
        Write-Host (Get-Date -Format G) " Error occured finding datastore for $VM"
        $ErrorOccured = $true
    }
    if ($ErrorOccured -eq $false) {
        try {
            New-PSDrive -Location $DatatStoreVM -Name ds -PSProvider VimDatastore -Root "\" -ErrorVariable $DataStoreError | Out-Null
        } catch {
            Write-Host (Get-Date -Format G) " Error occured finding datastore for $VM"
        }
        if (!$DataStoreError) {
            Set-Location ds:\
            cd $VM
            if (Test-Path vmware.log) {
                $LastWriteTime = Get-Item vmware.log | Select LastWriteTime
                Copy-DataStoreItem -Item vmware.log -Destination $Output\$vm.log
                set-Location C:
                Remove-PSDrive -Name ds -Confirm:$false
                $LastLine = Get-Content $Output\$vm.log | Select-Object -Last 1
                $LastLine = $LastLine.Split("vmx") | Select -First 1
                $LastLine = $LastLine.Split(".") | Select -First 1
                $Item = New-Object System.Object
                $Item | Add-Member -Type NoteProperty -Name VM -Value "$VM"
                $Item | Add-Member -Type NoteProperty -Name 'Powered Off' -Value "Unknown"
                $Item | Add-Member -Type NoteProperty -Name Notes -Value "No date listed in VSphere event logs. Entries are from VM Logs"
                $Item | Add-Member -Type NoteProperty -Name 'Last log write' -Value "$($LastWriteTime.LastWriteTime)"
                $Item | Add-Member -Type NoteProperty -Name 'Last log entry' -Value "$($LastLine.ToString())"
                $VMResults += $Item
                Remove-Item $Output\$vm.log
            } else {
                Write-Host (Get-Date -Format G) " Error finding path with $($VM.Name)"
                set-Location C:
                Remove-PSDrive -Name ds -Confirm:$false
            }
        }
    }
    Write-Host (Get-Date -Format G) " Processed $Counter of $($RemainingOffVms.Count)"
}

Write-Host (Get-Date -Format G) " Generating Report"

$Formatting = "<style>"
$Formatting = $Formatting + "BODY{background-color:white;}"
$Formatting = $Formatting + "FONT{font-family:arial;}"
$Formatting = $Formatting + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$Formatting = $Formatting + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$Formatting = $Formatting + "TD{border-width: 1px;padding: 10px;border-style: solid;border-color: black;}"
$Formatting = $Formatting + "</style>"
$VMResults | ConvertTo-Html -Title "Powered off VMWare Virtual Machines" -Head $Formatting -Body (Get-Date) -PreContent "<P>Generated by Tom's Script.</P><P>Pulled from $Server</P>" > $Output\Report.htm

Write-Host (Get-Date -Format G) "Report located on $Output\Report.htm"
Sleep(10)