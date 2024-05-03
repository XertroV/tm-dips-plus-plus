
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
