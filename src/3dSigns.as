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
        if (UI::BeginMenu("Stad. Signs")) {
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
            UI::BeginDisabled(!S_Enable3dSigns);
            if (UI::Button("Cycle Screens")) {
                startnew(Cycle3dScreens);
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
                if (l.AttachId == "155_Stadium" || l.AttachId == "2x3_Stadium") {
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
                if (l.AttachId == "155_Stadium" || l.AttachId == "2x3_Stadium") {
                    l.Type = CGameUILayer::EUILayerType::ScreenIn3d;
                    if (l.AttachId == "155_Stadium") {
                        l.ManialinkPageUtf8 = GetStadiumScreenCode();
                    } else if (l.AttachId == "2x3_Stadium") {
                        l.ManialinkPageUtf8 = GetStadiumSideCode();
                    }
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

#if DEV
    const uint loopNewClipTime = 60000;
#else
    const uint loopNewClipTime = 600000;
#endif

    void LoopUpdate3dScreens() {
        uint lastChangeTime = Time::Now;;
        while (g_Active) {
            sleep_fix(100);
            // if (!signsApplied) continue;
            if (!S_Enable3dSigns) continue;
            if (!g_Active) return;
            if (Time::Now - lastChangeTime > loopNewClipTime) {
                lastChangeTime = Time::Now;
                Cycle3dScreens();
            }
        }
    }

    void Cycle3dScreens() {
        dev_trace('Cycle3dScreens');
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
                if (l.AttachId == "155_Stadium") {
                    dev_trace('updated 155');
                    l.ManialinkPageUtf8 = GetStadiumScreenCode();
                } else if (l.AttachId == "2x3_Stadium") {
                    dev_trace('updated 2x3');
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
        "https://assets.xk.io/d++/vid/carljr-nice-physics.webm",
        "https://assets.xk.io/d++/vid/dont-pull-a-lars-scrapie.webm"
    };
    const string vidLinkPrefix = "https://assets.xk.io/d++/vid/";

    string currVideoLink;
    string nextVid;
    string ChooseRandomVid() {
        startnew(CheckForNewClipLinks);
        nextVid = videoLinks[Math::Rand(0, videoLinks.Length)];
        if (nextVid == currVideoLink) {
            nextVid = videoLinks[Math::Rand(0, videoLinks.Length)];
        }
        if (nextVid == currVideoLink) {
            nextVid = videoLinks[Math::Rand(0, videoLinks.Length)];
        }
        currVideoLink = nextVid;
        dev_trace('[ScreensIn3d] set curr video link: ' + currVideoLink);
        return currVideoLink;
    }

    void CheckForNewClipLinks() {
        Net::HttpRequest@ req = Net::HttpGet("https://assets.xk.io/d++/vid/clip-links.txt");
        while (!req.Finished()) yield();
        if (req.ResponseCode() != 200) return;
        auto clips = req.String().Split("\n");
        string[] toLoadSilently = {};
        // trace('Got clips: ' + string(Json::Write(clips.ToJson())));
        for (uint i = 0; i < clips.Length; i++) {
            auto clip = clips[i].Trim();
            if (clip.Length < 7) continue;
            clip = vidLinkPrefix + clip;
            clips[i] = clip;
            if (videoLinks.Find(clip) == -1) {
                videoLinks.InsertLast(clip);
                dev_trace('Inserted new clip: ' + clip);
                toLoadSilently.InsertLast(clip);
            }
        }
        // trace('Got clips: ' + string(Json::Write(clips.ToJson())));
        // trace('Got videoLinks: ' + string(Json::Write(videoLinks.ToJson())));
        for (uint i = 0; i < videoLinks.Length; i++) {
            if (clips.Find(videoLinks[i]) == -1) {
                dev_trace('Removed clip: ' + videoLinks[i]);
                videoLinks.RemoveAt(i);
                i--;
            }
        }

        if (toLoadSilently.Length > 0) {
            LoadClipsSilently(toLoadSilently);
        }
    }

    void LoadClipsSilently(string[]@ clips) {
        string[] lines = {};
        for (uint i = 0; i < clips.Length; i++) {
            auto clip = clips[i];
            lines.InsertLast('<video id="dd2-vid" size="320 180" pos="0 0" halign="center" valign="center" data="VIDEO_LINK" play="0" loop="1" music="0" />');
            lines[lines.Length - 1] = lines[lines.Length - 1].Replace("VIDEO_LINK", clip);
        }
        string vidLines = string::Join(lines, "\n");
        auto layer = FindUILayerWAttachId("dpp_load_clips");
        if (layer is null) @layer = CreateUILayer("dpp_load_clips");
        else layer.IsVisible = true;
        if (layer is null) {
            warn("Could not find or create UI layer for loading clips");
            return;
        }
        string code = """
<?xml version="1.0" encoding="utf-8" standalone="yes" ?>
<manialink version="3" name="DD2_WebmsSilentLoadEarly">
UI_ELEMENTS
</manialink>
""";
        code = code.Replace("UI_ELEMENTS", vidLines);
        layer.ManialinkPageUtf8 = code;
        layer.IsVisible = false;
    }

    CGameUILayer@ FindUILayerWAttachId(const string &in attachId, uint skipN = 0) {
        auto app = GetApp();
        try {
            auto cmap = app.Network.ClientManiaAppPlayground;
            for (uint i = 0; i < cmap.UILayers.Length; i++) {
                auto l = cmap.UILayers[i];
                if (l.AttachId == attachId) {
                    if (skipN > 0) {
                        skipN--;
                    } else {
                        return l;
                    }
                }
            }
        } catch {
            warn("exception finding UI layer: " + getExceptionInfo());
        }
        return null;
    }

    CGameUILayer@ CreateUILayer(const string &in attachId) {
        auto app = GetApp();
        try {
            auto cmap = app.Network.ClientManiaAppPlayground;
            auto layer = cmap.UILayerCreate();
            layer.AttachId = attachId;
            return layer;
        } catch {
            warn("exception creating UI layer: " + getExceptionInfo());
        }
        return null;
    }
}
