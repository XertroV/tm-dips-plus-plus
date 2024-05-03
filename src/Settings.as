/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
[Setting hidden]
bool S_Enabled = true;

[Setting category="General" name="Volume" min=0 max=1]
float S_VolumeGain = 0.55;

[Setting hidden]
float S_MinimapPlayerLabelFS = 24.0;

[Setting hidden]
bool S_ShowMinimap = true;

[Setting hidden]
float S_PBAlertFontSize = 82.0;

[Setting hidden]
bool S_ShowDDLoadingScreens = true;

[Setting hidden]
#if DEV
bool S_EnableMainMenuPromoBg = true;
#else
bool S_EnableMainMenuPromoBg = false;
#endif

[Setting hidden]
TimeOfDay S_MenuBgTimeOfDay = TimeOfDay::Night;

[Setting hidden]
Season S_MenuBgSeason = Season::Spring;
