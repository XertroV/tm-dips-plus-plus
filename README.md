
*Can you hear the thunder...*

# Dips++

The official companion plugin for *Deep Dip 2*.

Plugin features include:
* Voice lines + subtitles for each floor
* Additional lore
* Height Tracker
* PB Tracker
* Falls Tracker
* Jump Speed Indicator
* and even more stats!
* Over 400 Collectables
* Floor Gang Celebrator
* Loading Screens
* A Main Menu Surprise

# Maps other than Deep Dip 2

You can enable Dips++ for other maps (no leaderboard, but stats and minimap aka dip stick will show).

To do so, mappers should add a 'Dips Spec' to their map comment. (For maps already published, create one and then DM it to XertroV with the map UID and it can be uploaded to a place the plugin checks.)

## Dips Spec Example

```
--BEGIN-DPP--
--
-- Dips++ Custom Map example; comments using `--`, `//` or `#`
--   * Structured as `<key> = <value>` pairs.
--
-- `url` is optional; this is where features like custom triggers,
--   asset lists, etc will go in future.
url = https://assets.xk.io/d++maps/deepdip1-spec.json

-- start and finish will be inferred if not present based on map waypoint locations.
start = 26.0
finish = 1970.0

-- floors start at 00 for the ground and increase from there. If you miss a number,
--   it will be set to a height of -1.0.
floor00 = 4.0
floor01 = 138
floor02 = 266.0
floor03 = 394.0
floor04 = 522.0
floor05 = 650.0
floor06 = 816.0
floor07 = 906.0
floor08 = 1026.0
floor09 = 1170.0
floor10 = 1296.0
floor11 = 1426.0
floor12 = 1554.0
floor13 = 1680.0
floor14 = 1824.0
floor15 = 1938.0

-- if true, the last floor's label will be 'End' instead of '15' or whatever floor it is.
--   (default: false)
lastFloorEnd = true

-- Blank lines are ignored.
-- Anything outside the BEGIN and END markers is ignored.

--END-DPP--
```

## API & Data

Data disclaimer: This plugin will transmit data to the Dips++ server for the duration of the Deep Dip 2 event.

Data is available via the Dips++ server. Some very brief documentation about available routes is found here: <https://dips-plus-plus.xk.io/api/routes>.

More endpoints will be added over the coming days.

Contact @XertroV for questions or requests.












- detect mediatracker triggering

- floor names, how to nicely animate with the MT stuff / integrate

- minimap - floor indicators, alternating colors on mm bg.
- dedicated player height thing (like heightometer)
- geep gip for ridiculous falls
- track mb heights / map stats / pb
- start room with map base config


- hover side to bring out per player stats
  - draw 1 minimap per player and move player to each. Hovering each column brings up stats for that player.

- unbind reminders?

- stats for time spent on each floor


if someone stays on a floor for some time but didn't trigger the floor intro thing, show it anyway?


todo:
- [ ] player fall counter
- [ ] high scores: PlayerStats namespace
- [ ] persistence for player stuff
- [ ] <https://discord.com/channels/888468779238055947/1203420891438907443/1227904293626052628> if we want to avoid this, I can add a check for where the fall started. And only if the player isn't falling or the fall started on floor 4 will it trigger.
- [ ] proximity voice chat
- [ ] notification for achievements / collections

- [ ] deep dip 2 first title to sync with tutorial voice line
- [ ] vaelyn cute image in plugin credits
  - little popup of avatar when voice lines speaking, next to subtitles
- [ ] vaelyn credit in credits for voice line
  - during intro voice lines, show writen and voiced by vaelyn (show for full time)
- [ ] totd + lobby map easter eggs

- [ ] finish stuff, detect chat and hide main GZ overlay
