## Purpose
Polls a list of computers and checks to see if they are available via SMB. Uses a file `ComputerList.txt` as the list, which should be one computer per line.

This also checks if the computer is available via ICMP connections. This script runs infinitely so set a scheduled task for once a day to run this script. This is designed to identify when computers fail to connect and diagnose faults with fileservers and the like.

Useful for intermittent connection faults via SMB as it will at least give you the time it failed.

## Important notes
* Takes longer the more computers there are
* Runs sequentially through the list
* Firewalls will block this script
* This is an archived script and may not work 