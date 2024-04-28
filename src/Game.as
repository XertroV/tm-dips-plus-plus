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
