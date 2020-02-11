# Convert Wua History ResultCode to a Name
# 0, and 5 are not used for history
# See https://msdn.microsoft.com/en-us/library/windows/desktop/aa387095(v=vs.85).aspx
# This code was not made by me but instead found online.
# Usage: UpdatesInstalltoday.ps1
# Important: Requires the C:/Temp/ folder to be created BEFORE running the script, does not create the folder by itself.

function Convert-WuaResultCodeToName
{
    param(
        [Parameter(Mandatory=$true)]
        [int] $ResultCode
    )

    $Result = $ResultCode
    switch($ResultCode)
    {
      2 {
        $Result = "Succeeded"
      }
      3 {
        $Result = "Succeeded With Errors"
      }
      4 {
        $Result = "Failed"
      }
    }

    return $Result
}

function Get-WuaHistory
{

  # Get a WUA Session
  $session = (New-Object -ComObject 'Microsoft.Update.Session')

  # Query the latest 1000 History starting with the first recordp     
  $history = $session.QueryHistory("",0,1000) | ForEach-Object {
     $Result = Convert-WuaResultCodeToName -ResultCode $_.ResultCode

     # Make the properties hidden in com properties visible.
     $_ | Add-Member -MemberType NoteProperty -Value $Result -Name Result
     $Product = $_.Categories | Where-Object {$_.Type -eq 'Product'} | Select-Object -First 1 -ExpandProperty Name
     $_ | Add-Member -MemberType NoteProperty -Value $_.UpdateIdentity.UpdateId -Name UpdateId
     $_ | Add-Member -MemberType NoteProperty -Value $_.UpdateIdentity.RevisionNumber -Name RevisionNumber
     $_ | Add-Member -MemberType NoteProperty -Value $Product -Name Product -PassThru

     Write-Output $_
  } 

  #Remove null records and only return the fields we want
  $history | 
      Where-Object {![String]::IsNullOrWhiteSpace($_.title)} | 
          Select-Object Result, Date, Title, SupportUrl, Product, UpdateId 
}  
$filterDate = (Get-Date).AddDays(-1).Date
$OutputFilename = 'C:\Temp\' + $(get-date -f yyyy-MM-dd) + '-' + $env:COMPUTERNAME + '-Updates.csv'
Get-WuaHistory | Where {$_.Date -ge $filterDate} | Export-Csv $OutputFilename