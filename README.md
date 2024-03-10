#

License: Public Domain

Authors: XertroV

Suggestions/feedback: @XertroV on Openplanet discord

Code/issues: [https://github.com/XertroV/tm-play-map](https://github.com/XertroV/tm-play-map)

GL HF



- floor names, how to nicely animate with the MT stuff / integrate



if someone stays on a floor for some time but didn't trigger the floor intro thing, show it anyway?




rough idea:
 - need to monitor all vehicles and players
 - need to map between the two
 - need to update every frame
 -


frame:
- check in map
  - no map -> deactivate
- check player count
  - if changed, update players & order
  - update player table
- (players are sorted now)
- for each player
  - read vehicle id and update table references
- for each vehicle id
  - look up player
  - update player state tracked info
  - while processing player state update, emit events
- for each event (drain)
  - process, update state
- render
