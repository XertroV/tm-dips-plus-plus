const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$fd5";
const string MenuTitle = MenuIconColor + Icons::ArrowDown + "\\$z " + PluginName;

UI::Font@ f_MonoSpace = null;
int f_Nvg_OswaldLightItalic = nvg::LoadFont("Fonts/Oswald-LightItalic.ttf", true, true);
int f_Nvg_ExoLightItalic = nvg::LoadFont("Fonts/Exo-LightItalic.ttf", true, true);
int f_Nvg_ExoRegularItalic = nvg::LoadFont("Fonts/Exo-Italic.ttf", true, true);
int f_Nvg_ExoRegular = nvg::LoadFont("Fonts/Exo-Regular.ttf", true, true);
int f_Nvg_ExoMedium = nvg::LoadFont("Fonts/Exo-Medium.ttf", true, true);
int f_Nvg_ExoMediumItalic = nvg::LoadFont("Fonts/Exo-MediumItalic.ttf", true, true);
int f_Nvg_ExoBold = nvg::LoadFont("Fonts/Exo-Bold.ttf", true, true);
// int g_nvgFont = nvg::LoadFont("RobotoSans.ttf", true, true);

#if DEV
bool DEV_MODE = true;
#elif
bool DEV_MODE = false;
#endif

void LoadFonts() {
	@f_MonoSpace = UI::LoadFont("DroidSansMono.ttf");
}

void Main() {
    startnew(LoadFonts);
    g_LocalPlayerMwId = GetLocalPlayerMwId();
    startnew(AwaitLocalPlayerMwId);
    // GenerateHeightStrings();
    InitDD2TriggerTree();
    sleep(500);
    // auto size = vec2(400, 100);
    // auto pos = vec2((Draw::GetWidth() - size.x) / 2.0, 200);
    // titleScreenAnimations.InsertLast(FloorTitleGeneric("Floor 00 - SparklingW", pos, size));
    startnew(RefreshAssets);
}
//remove any hooks
void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    if (textOverlayAudio !is null) {
        textOverlayAudio.StartFadeOutLoop();
        @textOverlayAudio = null;
    }
    ClearAnimations();
}




bool g_Active = false;
vec2 g_screen;
bool IsVehicleActionMap;

void RenderEarly() {
    IsVehicleActionMap = UI::CurrentActionMap() == "Vehicle";
    g_screen = vec2(Draw::GetWidth(), Draw::GetHeight());
    RenderEarlyInner();
    UpdateDownloads();
    if (g_Active) {
        Minimap::RenderEarly();
    }
}

void Render() {
    DownloadProgress::Draw();
    // dev mode => render in menus
    if (g_Active || DEV_MODE) {
        RenderTitleScreenAnims();
    }
    if (g_Active) {
        RenderSubtitles();
        RenderTextOveralys();
        RenderAnimations();
        Minimap::Render();
        HUD::Render(PS::viewedPlayer);
    }
    RenderDebugWindow();
}

bool RenderEarlyInner() {
    bool wasActive = g_Active;
    // calling Inactive sets g_Active to false
    if (!S_Enabled) return Inactive(wasActive);
    auto app = GetApp();
    if (app.RootMap is null) return Inactive(wasActive);
    if (app.CurrentPlayground is null) return Inactive(wasActive);
    if (app.CurrentPlayground.GameTerminals.Length == 0) return Inactive(wasActive);
    if (app.CurrentPlayground.GameTerminals[0].ControlledPlayer is null) return Inactive(wasActive);
    if (app.CurrentPlayground.UIConfigs.Length == 0) return Inactive(wasActive);
    if (app.CurrentPlayground.UIConfigs[0].UISequence != CGamePlaygroundUIConfig::EUISequence::Playing) return Inactive(wasActive);
    // ! uncomment this to enable map UID check
    if (!MapMatches(app.RootMap)) return Inactive(wasActive);
    if (!wasActive) EmitGoingActive(true);
    g_Active = true;
    PS::UpdatePlayers();
    return true;
}



/** Render function called every frame intended only for menu items in `UI`.
*/
void RenderMenu() {
    if (UI::MenuItem(PluginName + ": Show Falls On Left Side", "", g_ShowFalls)) {
        g_ShowFalls = !g_ShowFalls;
        S_ShowMinimap = g_ShowFalls;
    }
    if (UI::MenuItem(PluginName + ": Debug Window", "", g_DebugOpen)) {
        g_DebugOpen = !g_DebugOpen;
    }
    if (UI::MenuItem(PluginName + ": Show Minimap", "", S_ShowMinimap)) {
        S_ShowMinimap = !S_ShowMinimap;
    }
    if (UI::MenuItem(PluginName + ": Activate for this map")) {
        auto map = GetApp().RootMap;
        if (map is null) {
            NotifyError("No map found");
        } else {
            S_ActiveForMapUids = map.EdChallengeId;
        }
    }
    if (UI::MenuItem(PluginName + ": Deactivate for this map")) {
        S_ActiveForMapUids = "";
    }
}

[Setting hidden]
bool g_ShowFalls = true;




void RenderSubtitles() {
    RenderSubtitleAnims();
}

void RenderTextOveralys() {
    if (textOverlayAnims.Length == 0) return;
    for (uint i = 0; i < textOverlayAnims.Length; i++) {
        if (textOverlayAnims[i].Update()) {
            textOverlayAnims[i].Draw();
        } else {
            textOverlayAnims[i].OnEndAnim();
            textOverlayAnims.RemoveAt(i);
            i--;
        }
    }
}

void RenderSubtitleAnims() {
    if (subtitleAnims.Length == 0) return;
    for (uint i = 0; i < subtitleAnims.Length; i++) {
        if (subtitleAnims[i].Update()) {
            subtitleAnims[i].Draw();
        } else {
            subtitleAnims[i].OnEndAnim();
            subtitleAnims.RemoveAt(i);
            i--;
        }
    }
}

void RenderTitleScreenAnims() {
    if (titleScreenAnimations.Length == 0) return;
    if (titleScreenAnimations[0].Update()) {
        titleScreenAnimations[0].Draw();
    } else {
        titleScreenAnimations[0].OnEndAnim();
        // trace("Removing title anim: " + titleScreenAnimations[0].ToString());
        titleScreenAnimations.RemoveAt(0);
    }
    // for (uint i = 0; i < titleScreenAnimations.Length; i++) {
    //     // titleScreenAnimations[i].Draw();
    // }
}


void RenderAnimations() {
    nvg::Reset();
    nvg::FontFace(f_Nvg_ExoRegularItalic);
    nvg::FontSize(40.0);
    nvg::Translate(vec2(150, 400.0));
    nvg::TextAlign(nvg::Align::Left | nvg::Align::Top);

    // vec2 pos;
    uint[] toRem;

    Animation@ anim;
    uint s, e;
    for (uint i = 0; i < statusAnimations.Length; i++) {
        @anim = statusAnimations[i];
        if (anim !is null && anim.Update()) {
            if (!g_ShowFalls) continue;
            s = Time::Now;
            auto y = anim.Draw().y;
            if (Time::Now - s > 1) {
                warn("Draw took " + (Time::Now - s) + "ms: " + anim.ToString(i) + " y-nan: " + Math::IsNaN(y) + ", y-inf: " + Math::IsInf(y) + ", y: " + y);
            }
            if (Math::IsNaN(y)) continue;
            // if (Math::IsNaN(y)) {
            //     trace("NaN " + i + ", " + anim.name);
            // }
            // if (Math::IsInf(y)) {
            //     trace("Inf " + i + ", " + anim.name);
            // }
            if (y > 0.05) nvg::Translate(vec2(0, y));
        } else {
            anim.OnEndAnim();
            toRem.InsertLast(i);
        }
    }

    if (toRem.Length == 0) return;
    // trace("removing " + toRem.Length + " / first: " + toRem[0]);
    for (int i = toRem.Length - 1; i >= 0; i--) {
        statusAnimations.RemoveAt(toRem[i]);
        // trace('removed: ' + toRem[i]);
    }
}











// when we're inactive we call this so we can do other things first
bool Inactive(bool wasActive) {
    if (wasActive) {
        EmitGoingActive(false);
    }
    g_Active = false;
    return false;
}

float g_DT;
/** Called every frame. `dt` is the delta time (milliseconds since last frame).
*/
void Update(float dt) {
    g_DT = dt;
}


vec2 SmoothLerp(vec2 from, vec2 to, float t) {
    // drawAtWorldPos = Math::Lerp(lastDrawWorldPos, drawAtWorldPos, 1. - Math::Exp(animLambda * lastDt * 0.001));
    // animLambda: more negative => faster movement
    return Math::Lerp(from, to, 1. - Math::Exp(-6.0 * g_DT * 0.001));
}


bool EmitGoingActive(bool val) {
    // todo
    if (!val) {
        PS::ClearPlayers();
        ClearAnimations();
        TriggerCheck_Reset();
        TitleGag::Reset();
    } else {
        startnew(OnGoingActive);
    }
    return val;
}


void OnGoingActive() {
    // while (g_Active) {
    //     // actions we need to take each active frame
    //     yield();
    // }
}


void EmitOnPlayerRespawn(PlayerState@ ps) {
    if (ps.isLocal) {
        TitleGag::OnPlayerRespawn();
    }
}



uint g_LocalPlayerMwId = -1;

void AwaitLocalPlayerMwId() {
    while (g_LocalPlayerMwId == -1) {
        g_LocalPlayerMwId = GetLocalPlayerMwId();
        if (g_LocalPlayerMwId == -1) sleep(1000);
        else break;
    }
    // for (uint i = 0; i < PS::players.Length; i++) {
    //     PS::players[i].CheckUpdateIsLocal();
    // }
}

uint GetLocalPlayerMwId() {
    auto app = GetApp();
    if (app.LocalPlayerInfo is null) return -1;
    return app.LocalPlayerInfo.Id.Value;
}

uint GetViewedPlayerMwId(CSmArenaClient@ cp) {
    try {
        return cast<CSmPlayer>(cp.GameTerminals[0].GUIPlayer).Score.Id.Value;
    } catch {
        return 0;
    }
}

MemoryBuffer@ ReadToBuf(const string &in path) {
    IO::File file(path, IO::FileMode::Read);
    return file.Read(file.Size());
}



vec4 GenRandomColor(float alpha = 1.0) {
    return vec4(vec3(Math::Rand(0.1, 1.0), Math::Rand(0.1, 1.0), Math::Rand(0.1, 1.0)).Normalized(), alpha);
}



void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}
void Dev_Notify(const string &in msg) {
#if DEV
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
#endif
}

void NotifySuccess(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, vec4(.4, .7, .1, .3), 10000);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}


void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::SetNextWindowSize(400, 0, UI::Cond::Appearing);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
    }
}
