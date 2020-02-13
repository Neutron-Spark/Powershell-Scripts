## Purpose
This gets the distribution groups from AD and compares them to the distribution groups in Exchange and shows the differences

## Requirements 
Running on a computer which has access to the Active Directory and to Exchange, along with the Active Directory modules installed. If you have MFA enabled for Exchange online this will most likely fail.

## How to use examples
```powershell 
CompareDistributionGroups.ps1 
#This runs in its purest form. Must have access to the AD server and to establish powershell connections to Exchange Online. The script must be run from a location which allows the script itself to save files there
CompareDistributionGroups.ps1 -SkipExchange $true -ToCSV $true -CSVPath  C:\temp\ADCSV.csv 
#Skips exchange and only does AD, exporting it to a specified location
CompareDistributionGroups.ps1 -ImportADCSV $true -CSVPath C:\temp\ADCSV.csv -Output C:\temp\report.htm 
#This runs without polling AD and takes a generated CSV instead and outputs the report to the specified location
```

## Version History
1.0 23/11/2017 - Initial Release

1.1 23/11/2017 - Added in output for users to see which group is being processed at the time

1.2 24/11/2017 - Allowed for recursion for the Exchange Distribution groups, tidy up of code and addition of command line switches

1.3 27/11/2017 - Commenting for clarity, fixed bug with exporting to csv going to the wrong path, removed unneeded column and changed names of report headers to be more useful

## Important Notes
* This script must be run on a domain joined computer if AD is polled, as it uses the computers AD membership to find the AD Server
* This is an archived script and may not work