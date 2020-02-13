## Purpose
Checks the user folder location (\\Bistech\storage\Users) and compares it to disabled users. Matches any disabled users SamAccountName with a folder named the same thing and measures the size of it. 

In short, this script alerts the IT Admin on what folders haven't been cleared up after a user has been disabled.

## Current Version
1.0 - Released version

## Known Issues
* Only works with a user account which is a domain user due to needed read rights to all of the user folders

## Restrictions
* Doesn't actually do anything with the folders, simply alerts the user.

## Example Output
```
Disabled User Folder Alert
26/09/2017 10:41:06
Run on LAPTOP018

26/09/2017 10:40:46 Script started. Adding AD module....
26/09/2017 10:40:46 Generating list of disabled users and comparing to user folders...
26/09/2017 10:40:46 Users that are disabled and that have a folder in \Users
26/09/2017 10:40:46 krbtgt, Size: 0 MB
26/09/2017 10:40:46 JohnSmith, Size: 1523 MB
```

## Important Notes
* This is an archived script and may not work