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
bool S_ShowWhenUIHidden = false;

[Setting hidden]
bool S_HideMovieTitles = false;

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
bool S_EnableMainMenuPromoBg = false;

[Setting hidden]
TimeOfDay S_MenuBgTimeOfDay = TimeOfDay::Night;

[Setting hidden]
Season S_MenuBgSeason = Season::Spring;

TimeOfDay ComboTimeOfDay(const string &in label, TimeOfDay v) {
    if (UI::BeginCombo(label, tostring(v), UI::ComboFlags::None)) {
        if (UI::Selectable("Morning", v == TimeOfDay::Morning)) v = TimeOfDay::Morning;
        if (UI::Selectable("Day", v == TimeOfDay::Day)) v = TimeOfDay::Day;
        if (UI::Selectable("Evening", v == TimeOfDay::Evening)) v = TimeOfDay::Evening;
        if (UI::Selectable("Night", v == TimeOfDay::Night)) v = TimeOfDay::Night;
        UI::EndCombo();
    }
    return v;
}

Season ComboSeason(const string &in label, Season v) {
    if (UI::BeginCombo(label, tostring(v), UI::ComboFlags::None)) {
        if (UI::Selectable("Spring", v == Season::Spring)) v = Season::Spring;
        if (UI::Selectable("Summer", v == Season::Summer)) v = Season::Summer;
        if (UI::Selectable("Autumn", v == Season::Autumn)) v = Season::Autumn;
        if (UI::Selectable("Winter", v == Season::Winter)) v = Season::Winter;
        UI::EndCombo();
    }
    return v;
}
