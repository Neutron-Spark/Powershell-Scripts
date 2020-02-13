## Purpose
Dynamically add Servers to specific WSUS groups, alternating between two groups if more than one Server needs to be added. This is so computers are never left out of patch groups
1
## Known Issues
* If 1 computer is added at a time, WSUS Group 1 will always be picked, leading to a disproportionate amount of computers on one side and therefore rebooting at one time.

## Restrictions
* None
