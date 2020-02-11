# Name: CompareDistributionGroups.ps1
# Author: Tom Bestow
# Version: 1.3
# Date Created: 23/11/2017
# Purpose: This gets the distribution groups from AD and compares them to the distribution groups in Exchange and shows the differences
# Requirements: Running on a computer which has access to the Active Directory and to Exchange, along with the Active Directory modules installed. If you have MFA enabled for Exchange online this will most likely fail.
# How to use examples: 
<#
## WARNING | This script must be run on a domain joined computer if AD is polled, as it uses the computers AD membership to find the AD Server | WARNING ##

CompareDistributionGroups.ps1 #This runs in its purest form. Must have access to the AD server and to establish powershell connections to Exchange Online. The script must be run from a location which allows the script itself to save files there
CompareDistributionGroups.ps1 -SkipExchange $true -ToCSV $true -CSVPath  C:\temp\ADCSV.csv #Skips exchange and only does AD, exporting it to a specified location
CompareDistributionGroups.ps1 -ImportADCSV $true -CSVPath C:\temp\ADCSV.csv -Output C:\temp\report.htm #This runs without polling AD and takes a generated CSV instead and outputs the report to the specified location

#>

#Version History
#1.0 23/11/2017 - Initial Release
#1.1 23/11/2017 - Added in output for users to see which group is being processed at the time
#1.2 24/11/2017 - Allowed for recursion for the Exchange Distribution groups, tidy up of code and addition of command line switches
#1.3 27/11/2017 - Commenting for clarity, fixed bug with exporting to csv going to the wrong path, removed unneeded column and changed names of report headers to be more useful

param (
    [Boolean]$SkipAD = $false, #Skips AD interrogation, takes precedence over Importing AD CSV files
    [Boolean]$SkipExchange = $false, #Skips Exchange interrogation
    [Boolean]$ToCSV = $false, #Outputs AD interrogation ONLY to a CSV
    [Boolean]$ImportADCSV = $false, #Uses CSV values rather than polling AD
    [string]$CSVPath = "$PSScriptRoot\ADCSV.csv", #Path for Exporting OR Importing CSV file
    [string]$Output = "$PSScriptRoot" #Output for the report
)

## Arrays ##
$GroupsExch = @()
$GroupsAD = @()
$GroupsDiff = @()
$Members = @()
## ----- ##

## AD Check ##
if ($SkipAD -eq $false) {
    if ($ImportADCSV -eq $true) {
        Write-Host (Get-Date -Format G) " Importing CSV from $ImportADCSV"
        $ADGroups = Import-Csv $CSVPath
        foreach ($Group in $ADGroups) {
            $Members = $Group.MemberCount
            $Item = New-Object System.Object
            $Item | Add-Member -Type NoteProperty -Name Group -Value "$($Group.Group)"
            $Item | Add-Member -Type NoteProperty -Name MemberCount -Value "$($Members)"
            Write-Host (Get-Date -Format G) " Processing $($Group.Name)"
            $GroupsAD += $Item
        }


    } else {
        If (Get-Module -ListAvailable -Name ActiveDirectory) { # 
            Write-Host (Get-Date -Format G) " Importing ActiveDirectory addin..."
            Import-Module ActiveDirectory
        } else {
            Write-Host (Get-Date -Format G) " ActiveDirectory not installed, exiting"
            Exit
        }

        $ADGroups = Get-ADGroup -Filter {GroupCategory -eq "distribution"}
        Write-Host (Get-Date -Format G) " $($ADGroups.Count) AD Groups"

        foreach ($ADGroup in $ADGroups) {
            $Members = Get-ADGroupMember -Identity $ADGroup -Recursive | Select -ExpandProperty SAMAccountName
            $Item = New-Object System.Object
            $Item | Add-Member -Type NoteProperty -Name Group -Value "$($ADGroup.Name)"
            $Item | Add-Member -Type NoteProperty -Name MemberCount -Value "$($Members.Count)"
            Write-Host (Get-Date -Format G) " Processing $($ADGroup.Name)"
            $GroupsAD += $Item

        }
        if ($ToCSV -eq $true) {
            Write-Host (Get-Date -Format G) " Exporting CSV to $CSVPath"
            $GroupsAD | Export-CSV -Path "$CSVPath"
        }
    }
} else {
    Write-Host (Get-Date -Format G) " Active Directory skipped!"
}
## ----- ##

## Exchange Check ##
if ($SkipExchange -eq $false) {
    Write-Host (Get-Date -Format G) " Creating Powershell Session"
    $UserCredential = Get-Credential
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
    Import-PSSession $Session -AllowClobber


    $ExchangeGroups = Get-DistributionGroup -ResultSize Unlimited
    Write-Host (Get-Date -Format G) " $($ExchangeGroups.Count) Exchange Groups"

    function Get-MyADGroupMember ($GroupName) {
        $Members = (Get-DistributionGroupMember -Identity $GroupName.Id).Name
        foreach ($Member in $Members) {
            ## Test to see if the group member is a group itself
            if ($Member.RecipientType -like '*Group*') {
                Get-MyADGroupMember -GroupName $Member.Identity
            } else {
                $Member
            }
        }
    }

    foreach ($Group in $ExchangeGroups) {
        $Members = @()
        $Members = Get-MyADGroupMember -GroupName $Group
        $Item = New-Object System.Object
        $Item | Add-Member -Type NoteProperty -Name Group -Value "$($Group.Name)"
        $Item | Add-Member -Type NoteProperty -Name MemberCount -Value "$($Members.Count)"
        Write-Host (Get-Date -Format G) " Processing $($Group.Name)"
        $GroupsExch += $Item
    }

    Remove-PSSession $Session
} else {
    Write-Host (Get-Date -Format G) " Exchange skipped!"
}
## ----- ##

## Comparison ##
$CompareResults = Compare-Object $GroupsAD $GroupsExch -PassThru

foreach ($GroupFinal in $CompareResults) {
    $ExchangeGroupMemberCount = ($GroupsExch | Where-Object {$_.Group -eq $GroupFinal.Group} )
    $ADGroupMemberCount = ($GroupsAD | Where-Object {$_.Group -eq $GroupFinal.Group} )
    $Item = New-Object System.Object
    $Item | Add-Member -Type NoteProperty -Name Group -Value "$($GroupFinal.Group)"
    $Item | Add-Member -Type NoteProperty -Name Exchange-Online-Member-Count -Value "$($ExchangeGroupMemberCount.MemberCount)"
    $Item | Add-Member -Type NoteProperty -Name AD-OnPrem-Member-Count -Value "$($ADGroupMemberCount.MemberCount)"
    $GroupsDiff += $Item
}

$GroupsDiff | Format-Table -AutoSize
## ----- ##

## Report Generation ##
$Formatting = "<style>"
$Formatting = $Formatting + "BODY{background-color:white;}"
$Formatting = $Formatting + "FONT{font-family:arial;}"
$Formatting = $Formatting + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$Formatting = $Formatting + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$Formatting = $Formatting + "TD{border-width: 1px;padding: 10px;border-style: solid;border-color: black;}"
$Formatting = $Formatting + "</style>"
$GroupsDiff | ConvertTo-Html -Title "Distribution Groups that aren't Matched" -Head $Formatting -Body (Get-Date) -PreContent "<P>Generated by Tom's Script.</P>" > $PSScriptRoot\Report.htm
Invoke-Item $PSScriptRoot\Report.htm
## ----- ##