uint GetCurrentCPRulesTime() {
    auto app = GetApp();
    auto psapi = app.Network.PlaygroundClientScriptAPI;
    if (psapi is null) return 0;
    return psapi.GameTime;
}

bool IsPauseMenuOpen(bool requireFocused = true) {
    auto app = GetApp();
    if (requireFocused && !app.InputPort.IsFocused) return true;
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

uint GetGameTime() {
    auto pg = GetApp().Network.PlaygroundInterfaceScriptHandler;
    if (pg is null) return 0;
    return pg.GameTime;
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
        return VehicleState::GetVis(app.GameScene, player).AsyncState;
    } catch {
        return null;
    }
}
