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
        if (!S_Enable3dSigns) return;
        ChooseRandomVid();
        startnew(LoopUpdate3dScreens);
        if (Enable3dScreens(false)) {
            Cycle3dScreens();
            return;
        }
        auto app = GetApp();
        auto net = app.Network;
        while (app.RootMap is null) yield();
        while (app.CurrentPlayground is null) yield();
        while (net.ClientManiaAppPlayground is null) yield();
        while (net.ClientManiaAppPlayground !is null && net.ClientManiaAppPlayground.UILayers.Length < 20) yield();
        yield();
        yield();
        yield();
        if (!g_Active) return;
        if (app.PlaygroundScript !is null) {
            app.PlaygroundScript.UIManager.UIAll.DisplayControl_UseEsportsProgrammation = true;
        }

        ChooseRandomVid();

        auto cmap = net.ClientManiaAppPlayground;
        auto layer = cmap.UILayerCreate();
        layer.AttachId = "155_Stadium";
        layer.Type = CGameUILayer::EUILayerType::ScreenIn3d;
        layer.ManialinkPageUtf8 = GetStadiumScreenCode();

        // need 2 for more screen time
        @layer = cmap.UILayerCreate();
        layer.AttachId = "155_Stadium";
        layer.Type = CGameUILayer::EUILayerType::ScreenIn3d;
        layer.ManialinkPageUtf8 = GetStadiumScreenCode();

        // clip
        @layer = cmap.UILayerCreate();
        layer.AttachId = "2x3_Stadium";
        layer.Type = CGameUILayer::EUILayerType::ScreenIn3d;
        layer.ManialinkPageUtf8 = GetStadiumSideCode();

        // image prompting for clip submission
        @layer = cmap.UILayerCreate();
        layer.AttachId = "2x3_Stadium";
        layer.Type = CGameUILayer::EUILayerType::ScreenIn3d;
        layer.ManialinkPageUtf8 = StadiumSideCodeAlt;
    }

    string StadiumScreenCode = GetManialink("ml/155_Stadium.Script.xml");
    string StadiumSideCode = GetManialink("ml/2x3_Stadium.Script.xml");
    string StadiumSideCodeAlt = GetManialink("ml/2x3_StadiumAlt.Script.xml");

    string GetStadiumScreenCode() {
        return StadiumScreenCode.Replace("VIDEO_LINK", currVideoLink);
    }

    string GetStadiumSideCode() {
        return StadiumSideCode.Replace("VIDEO_LINK", currVideoLink);
    }

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

    bool Enable3dScreens(bool initIfAbsent = true) {
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
            if (!initIfAbsent) return false;
            SignsOnGoingActive();
            return true;
        } catch {
            warn("exception activating 3d screens: " + getExceptionInfo());
        }
        return false;
    }

    void LoopUpdate3dScreens() {
        uint lastChangeTime = 0;
        while (g_Active) {
            sleep(100);
            if (!signsApplied) continue;
            if (!S_Enable3dSigns) continue;
            if (!g_Active) return;
            if (Time::Now - lastChangeTime > 600000) {
                lastChangeTime = Time::Now;
                Cycle3dScreens();
            }
        }
    }

    void Cycle3dScreens() {
        auto link = ChooseRandomVid();
        auto app = GetApp();
        if (app.PlaygroundScript !is null) {
            app.PlaygroundScript.UIManager.UIAll.DisplayControl_UseEsportsProgrammation = true;
        }
        try {
            auto cmap = app.Network.ClientManiaAppPlayground;
            for (uint i = 0; i < cmap.UILayers.Length; i++) {
                auto l = cmap.UILayers[i];
                if (l.Type != CGameUILayer::EUILayerType::ScreenIn3d) continue;
                // start of our layers
                if (l.AttachId == "Stadium_155") {
                    l.ManialinkPageUtf8 = GetStadiumScreenCode();
                } else if (l.AttachId == "2x3_Stadium") {
                    l.ManialinkPageUtf8 = GetStadiumSideCode();
                    break;
                }
            }
            return;
        } catch {
            warn("exception activating 3d screens: " + getExceptionInfo());
        }
    }

    string[] videoLinks = {
        "https://assets.xk.io/d++/vid/lars-silly-mistake.webm",
        "https://assets.xk.io/d++/vid/byebye-bren.webm"
    };

    string currVideoLink;
    string ChooseRandomVid() {
        currVideoLink = videoLinks[Math::Rand(0, videoLinks.Length)];
        return currVideoLink;
    }
}
