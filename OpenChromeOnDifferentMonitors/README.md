## Purpose
Displays full screen chrome windows with different pages/websites displayed on each screen. This also makes sure that the screens are set to extend by flipping it to internal only then back to extend.

It was made to automate the displaying of PowerBi reports and dashboards across multiple screens (wallboards) every day.

## How to use
Edit the script to have the relevant URLs in it that you wish loaded, marked with `'URL X GOES HERE'`.

The more fiddly part is the `window-position` command. Note that this uses screen 1 as the point of reference for the furthest point left. So if screens are positioned: 2-1-3, screen 2 would have a NEGATIVE value for its reference. To find out the screens it should be on, remove the `--kiosk` part of the command.

The positioning doesn't have to be exact, as the `--kiosk` part of the command will make it full screen on whichever screen it's on. 

Finally, the script sets the screens to be only one screen then flips it to being extended. This was due to our environment and the TVs causing issues overnight as they went to sleep at different times.

## Why does it need a seperate profile?
By default Chrome loads additional windows on the same screen as an already open window for that profile, ignoring the commands. This means that if you load up one window full screen, any subsequent windows will load on that same screen.

The easiest way around this is to generate a new profile per screen needed. The downside to this is that any saved credentials will no longer exist so will need to be set up for that profile.

## Important Notes
* This requires Chrome to be installed
* Best run as a scheduled task
* If you are running PowerBi Reports the following URL switches can be appended:
    * `?chromeless=true` - Removes the frame around the outside
    * `&noSignUpCheck=1` - Stops PowerBi prompting to signing in