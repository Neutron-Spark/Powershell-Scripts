# Finds all server objects in AD, tries to login to them and then tries to remove the feature for SMBv1
# This script 

$Creds = Get-Credential
$Computers = Get-ADComputer -Filter {OperatingSystem -Like "*Server*"} | Select Name

foreach($Computer in $Computers) {
    try {
        $Result = Invoke-Command -ErrorAction Stop -ComputerName $Computer.Name -Credential $Creds -ScriptBlock {Get-WindowsFeature FS-SMB1 | Select PSComputerName,Name,Installed}
        if ($Result.Installed) {
            try {
                $RemovalResult = Invoke-Command -ErrorAction Stop -ComputerName $Computer.Name -Credential $Creds -ScriptBlock {Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol -NoRestart}
                if ($RemovalResult.RestartNeeded) {
                    Write-Host $Computer "SMBV1 removal completed. Restart needed"
                }
            } catch {
                Write-Host "$Computer could not be connected to for SMBV1 Removal"
            }
        } else {
            Write-Host "$Computer does not need SMBV1 Removed"
        }
    } catch {
        Write-Host "$Computer was not found or is currently offline"
    }
}