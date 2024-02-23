uint GetCurrentCPRulesTime() {
    auto app = GetApp();
    auto psapi = app.Network.PlaygroundClientScriptAPI;
    if (psapi is null) return 0;
    return app.Network.PlaygroundClientScriptAPI.GameTime;
}
