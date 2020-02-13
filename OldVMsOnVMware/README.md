## Purpose
This polls all of the powered off Virtual Machines on a VMWare cluster and find their power off time (if stored in the VSphere log) and compiles it into a report.

## Notes
Although this gets the power off time for some machines, others are more difficult due to the nature of the way individual VM logs are stored. Basically VMware only stores logs for poweron/off times for a limited time meaning the only other way of telling when a VM was powered on or off is via looking at the files itself and checking the last modified time. Alternatively you can check the log file stored with the VM. 

This script checks the log file associated with the VM to see its last write time with a specific event 'Powered Off' and presumes that was the last time the machine was powered off.

## Requirements
An AD Account with Admin permissions for the VSphere cluster

## How to use
```
 OldVMsOnVMWare.ps1 -Server VSPHERE_SERVER_ADDRESS -Output C:\SomeOtherLocation
 ```

## Important Notes
* This requires the VMware Powershell CLI modules (the script checks before starting properly for this)
* This is by no means accurate. It was designed to give an indication as to when a large number of VMs where on/off
* This is an archived script and may not work