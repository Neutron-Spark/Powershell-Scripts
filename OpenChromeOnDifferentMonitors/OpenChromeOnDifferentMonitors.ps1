# Displays full screen chrome windows with different pages displayed on each screen.
# This also makes sure that the screens are set to extend by flipping it to internal only then back to extend.

Add-Type -AssemblyName System.Windows.Forms
$Monitors = [System.Windows.Forms.Screen]::AllScreens

# Find the width of the screens. This takes into account multiple screens
$TotalWidth = 0

foreach ($Monitor in $Monitors) {
	$TotalWidth = $TotalWidth+($Monitor.bounds.Width)
}
Write-Host "Total Width of Screens = $TotalWidth"
# -------------------------

#Resetting Screens
DisplaySwitch.exe /internal
sleep 10
DisplaySwitch.exe /extend
sleep 10
# -------------------------

#Closing Chrome
$RunningChrome = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($RunningChrome) {
    Stop-Process -InputObject $RunningChrome
    Get-Process | Where-Object {$_.HasExited}
    }
# -------------------------

#Opening Chrome
& 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' --app="URL 1 GOES HERE" --window-position=1,0 --new-window --kiosk
& 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' --app="URL 2 GOES HERE" --window-position=-1200,0 --new-window --user-data-dir=c:/monitor2 --kiosk
& 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' --app="URL 3 GOES HERE" --window-position=-2400,0 --new-window --user-data-dir=c:/monitor3 --kiosk
# -------------------------

# Checks to be used for diagnostics, can be removed
if($Monitors.Count -lt 3) {
	Write-Host "One or more monitors is missing!"
}
else {
	Write-Host "Correct number of monitors"
}
# -------------------------