##### Script Information Here! #####
$JobName = "ConnectionChecker-$env:COMPUTERNAME"
$Log = "C:\Temp\$JobName-Log.txt"
#Version = 2.0
#Author = Tom Bestow
#Purpose = Checks a list of Computers and verifies connectivity via SMB. Checks a list of other device Addressess and pings them for a reply. Outputs failed logs and time to the log file. 
#This loops infinitely!
##### -------------------- #####

$path = 'C:\Temp'
$ErrorActionPreference = "Stop"

##### Workflow #####
Workflow WorkFlowTestConnection {
    Param(
        [string[]]$WFComputerList
    )
    $ErrorActionPreference = "Stop"

    $WFComputerList = Get-Content C:\Temp\ComputerList.txt
    Foreach -parallel ($Computer in $WFComputerList){
        if (!(Test-NetConnection $Computer -CommonTCPPort SMB -InformationLevel Quiet)){
            Write-Output "$(Get-Date -Format G) $Computer connection failed SMB Connection from $env:COMPUTERNAME"
        }
    }
    $WFOtherList = Get-Content C:\Temp\OtherList.txt
    ForEach -parallel ($Device in $WFOtherList){
        if (!(Test-Connection $Device -Count 1 -Quiet)){
             Write-Output "$(Get-Date -Format G) $Device connection failed ICMP from $env:COMPUTERNAME"
        }
    }
}
##### -------------------- #####

##### Script #####
Add-Content $Log -Value "$(Get-Date -Format G) Script started on $env:COMPUTERNAME" -PassThru
try {
    if (Test-Path "$path\ComputerList.txt" -PathType Leaf) {
        $ComputerList = Get-Content "$path\ComputerList.txt"
        Add-Content $Log -Value "$(Get-Date -Format G) List of windows computers to test: $ComputerList" -PassThru
    } else {
        Add-Content $Log -Value "$(Get-Date -Format G) No list of windows computers found at $path" -PassThru
    }
    
    if (Test-Path "$path\OtherList.txt" -PathType Leaf) {
        $OtherList = Get-Content "$path\OtherList.txt"
        Add-Content $Log -Value "$(Get-Date -Format G) List of other devices to test: $OtherList" -PassThru
    } else {
        Add-Content $Log -Value "$(Get-Date -Format G) No list of other devices found at $path" -PassThru
    }

} catch {
    Add-Content $Log -Value "$(Get-Date -Format G) Error with List of computers $path" -PassThru
}

Add-Content $Log -Value "$(Get-Date -Format G) Entering Loop" -PassThru

while ($true) {
    try{
        $Output = WorkFlowTestConnection($ComputerList)
    }catch{
        Add-Content $Log -Value "$(Get-Date -Format G) Error in Workflow, Stopping Script" -PassThru
        Exit
    }
    Add-Content $Log -Value $Output -PassThru
}

