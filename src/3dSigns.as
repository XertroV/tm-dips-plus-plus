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
bool S_Enable3dSigns = true;

namespace Signs3d {
    bool signsApplied = false;
    void SignsOnGoingActive() {
        if (S_Enable3dSigns) return;
        if (Enable3dScreens()) return;
        auto app = GetApp();
        auto net = app.Network;
        while (app.RootMap is null) yield();
        while (app.CurrentPlayground is null) yield();
        while (net.ClientManiaAppPlayground is null) yield();
        while (net.ClientManiaAppPlayground.UILayers.Length < 20) yield();
        yield();
        yield();
        yield();
        if (!g_Active) return;
        if (app.PlaygroundScript !is null) {
            app.PlaygroundScript.UIManager.UIAll.DisplayControl_UseEsportsProgrammation = true;
        }

        auto cmap = net.ClientManiaAppPlayground;
        auto layer = cmap.UILayerCreate();
        layer.AttachId = "155_Stadium";
        layer.Type = CGameUILayer::EUILayerType::ScreenIn3d;
        layer.ManialinkPageUtf8 = StadiumScreenCode;

        // need 2 for more screen time
        @layer = cmap.UILayerCreate();
        layer.AttachId = "155_Stadium";
        layer.Type = CGameUILayer::EUILayerType::ScreenIn3d;
        layer.ManialinkPageUtf8 = StadiumScreenCode;

        // clip
        @layer = cmap.UILayerCreate();
        layer.AttachId = "2x3_Stadium";
        layer.Type = CGameUILayer::EUILayerType::ScreenIn3d;
        layer.ManialinkPageUtf8 = StadiumSideCode;

        // image prompting for clip submission
        @layer = cmap.UILayerCreate();
        layer.AttachId = "2x3_Stadium";
        layer.Type = CGameUILayer::EUILayerType::ScreenIn3d;
        layer.ManialinkPageUtf8 = StadiumSideCodeAlt;
    }

    string StadiumScreenCode = GetManialink("ml/155_Stadium.Script.xml");
    string StadiumSideCode = GetManialink("ml/2x3_Stadium.Script.xml");
    string StadiumSideCodeAlt = GetManialink("ml/2x3_StadiumAlt.Script.xml");

    string GetManialink(const string &in name) {
        IO::FileSource f(name);
        return f.ReadToEnd();
    }

    void DrawMenu() {
        if (UI::BeginMenu("Stadium Signs")) {
            S_Enable3dSigns = UI::Checkbox("Enable 3D Signs", S_Enable3dSigns);
            UI::BeginDisabled(!g_Active);
            if (UI::Button("Disable Now")) {
                S_Enable3dSigns = false;
                startnew(Disable3dScreens);
            }
            if (UI::Button("Enable Now")) {
                S_Enable3dSigns = true;
                startnew(Enable3dScreensCoroF);
            }
            UI::EndDisabled();
            UI::EndMenu();
        }
    }

    void Disable3dScreens() {
        if (!g_Active) return;
        auto app = GetApp();
        if (app.PlaygroundScript !is null) {
            app.PlaygroundScript.UIManager.UIAll.DisplayControl_UseEsportsProgrammation = false;
        }
        try {
            auto cmap = app.Network.ClientManiaAppPlayground;
            for (uint i = 0; i < cmap.UILayers.Length; i++) {
                auto l = cmap.UILayers[i];
                if (l.Type != CGameUILayer::EUILayerType::ScreenIn3d) continue;
                if (l.AttachId == "Stadium_155" || l.AttachId == "2x3_Stadium") {
                    l.Type = CGameUILayer::EUILayerType::Normal;
                }
            }
        } catch {
            warn("exception removing 3d screens: " + getExceptionInfo());
        }
    }

    void Enable3dScreensCoroF() {
        Enable3dScreens();
    }

    bool Enable3dScreens() {
        if (!g_Active) return false;
        auto app = GetApp();
        if (app.PlaygroundScript !is null) {
            app.PlaygroundScript.UIManager.UIAll.DisplayControl_UseEsportsProgrammation = true;
        }
        try {
            uint found = 0;
            auto cmap = app.Network.ClientManiaAppPlayground;
            for (uint i = 0; i < cmap.UILayers.Length; i++) {
                auto l = cmap.UILayers[i];
                if (l.Type != CGameUILayer::EUILayerType::Normal) continue;
                if (l.AttachId == "Stadium_155" || l.AttachId == "2x3_Stadium") {
                    l.Type = CGameUILayer::EUILayerType::ScreenIn3d;
                    found++;
                }
            }
            if (found > 1) {
                return true;
            }
            SignsOnGoingActive();
            return true;
        } catch {
            warn("exception activating 3d screens: " + getExceptionInfo());
        }
        return false;
    }
}
