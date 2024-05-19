/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/
uint GetCurrentCPRulesTime() {
    auto app = GetApp();
    auto psapi = app.Network.PlaygroundClientScriptAPI;
    if (psapi is null) return 0;
    return psapi.GameTime;
}

bool IsPauseMenuOpen(bool requireFocused = true) {
    auto app = GetApp();
    bool isUnfocused = !app.InputPort.IsFocused && S_PauseWhenGameUnfocused;
    if (requireFocused && isUnfocused) return true;
    if (app.CurrentPlayground is null) return false;
    auto psapi = app.Network.PlaygroundClientScriptAPI;
    if (psapi is null) return false;
    return psapi.IsInGameMenuDisplayed;
}

bool IsImguiHovered() {
    return int(GetApp().InputPort.MouseVisibility) == 2;
}

bool PlaygroundExists() {
    return GetApp().CurrentPlayground !is null;
}

int GetGameTime() {
    auto pg = GetApp().Network.PlaygroundInterfaceScriptHandler;
    if (pg is null) return 0;
    return int(pg.GameTime);
}

int GetRaceTimeFromStartTime(int startTime) {
    return GetGameTime() - startTime;
}

CSceneVehicleVisState@ GetVehicleStateOfControlledPlayer() {
    try {
        auto app = GetApp();
        if (app.GameScene is null || app.CurrentPlayground is null) return null;
        auto player = cast<CSmPlayer>(GetApp().CurrentPlayground.GameTerminals[0].ControlledPlayer);
        if (player is null) return null;
        CSceneVehicleVis@ vis = VehicleState::GetVis(app.GameScene, player);
        if (vis is null) return null;
        return vis.AsyncState;
    } catch {
        return null;
    }
}

vec3 LocalPlayersColor() {
    return GetApp().LocalPlayerInfo.Color;
}

string _LocalPlayerWSID;
string LocalPlayersWSID() {
    if (_LocalPlayerWSID.Length < 15) {
        _LocalPlayerWSID = GetApp().LocalPlayerInfo.WebServicesUserId;
    }
    return _LocalPlayerWSID;
}
