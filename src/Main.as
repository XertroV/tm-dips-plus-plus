/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/

//
const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$fd5";
const string MenuTitle = MenuIconColor + Icons::ArrowDown + "\\$z " + PluginName;

UI::Font@ f_MonoSpace = null;
UI::Font@ f_Droid = null;
UI::Font@ f_DroidBig = null;
UI::Font@ f_DroidBigger = null;
// int f_Nvg_OswaldLightItalic = nvg::LoadFont("Fonts/Oswald-LightItalic.ttf", true, true);
// int f_Nvg_ExoLightItalic = nvg::LoadFont("Fonts/Exo-LightItalic.ttf", true, true);
int f_Nvg_ExoRegularItalic = nvg::LoadFont("Fonts/Exo-Italic.ttf", true, true);
int f_Nvg_ExoRegular = nvg::LoadFont("Fonts/Exo-Regular.ttf", true, true);
int f_Nvg_ExoMedium = nvg::LoadFont("Fonts/Exo-Medium.ttf", true, true);
int f_Nvg_ExoMediumItalic = nvg::LoadFont("Fonts/Exo-MediumItalic.ttf", true, true);
int f_Nvg_ExoBold = nvg::LoadFont("Fonts/Exo-Bold.ttf", true, true);
int f_Nvg_ExoExtraBold = nvg::LoadFont("Fonts/Exo-ExtraBold.ttf", true, true);
int f_Nvg_ExoExtraBoldItalic = nvg::LoadFont("Fonts/Exo-ExtraBoldItalic.ttf", true, true);
// int g_nvgFont = nvg::LoadFont("RobotoSans.ttf", true, true);

#if DEV
bool DEV_MODE = true;
#else
bool DEV_MODE = false;
#endif

void LoadFonts() {
	@f_MonoSpace = UI::LoadFont("DroidSansMono.ttf");
    @f_Droid = UI::LoadFont("DroidSans.ttf", 16.);
    @f_DroidBig = UI::LoadFont("DroidSans.ttf", 20.);
    @f_DroidBigger = UI::LoadFont("DroidSans.ttf", 26.);
}

DD2API@ g_api;
bool G_Initialized = false;

void Main() {
    g_LocalPlayerMwId = GetLocalPlayerMwId();
    yield();
    // ~~don't trust users not to just edit the file; get it from server instead.~~
    Stats::BackupForSafety();
    Stats::OnStartTryRestoreFromFile();
    RunEzMapStatsMigration();
    startnew(LoadFonts);
    startnew(LoadGlobalTextures);
    startnew(PreloadCriticalSounds);
    startnew(AwaitLocalPlayerMwId);
    startnew(RNGExtraLoop);
    startnew(MainMenuBg::OnPluginLoad);
    startnew(Volume::VolumeOnPluginStart);
    // GenerateHeightStrings();
    InitDD2TriggerTree();
    yield();
    startnew(GreenTimer::OnPluginStart);
    startnew(Wizard::OnPluginLoad);
    startnew(SF::LoadPtrs);
    startnew(WelcomeScreen::OnLoad);
    sleep(100);
    startnew(Donations::SetUpCheers);
    startnew(TwitchNames::AddDefaults);
    sleep(100);
    @g_api = DD2API();
    sleep(300);
    startnew(RefreshAssets);
    startnew(MagicSpectate::Load);
    startnew(SecretAssets::OnPluginStart);
    G_Initialized = true;
#if DEV
    // OnCameraUpdateHook.Apply();
    // OnCameraUpdateHook_Other.Apply();
    // RunFireworksTest();
#endif
}

// void UnloadSelfSoon() {
//     sleep(3000);
//     auto self = Meta::ExecutingPlugin();
//     Meta::UnloadPlugin(self);
// }



//remove any hooks
void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    Stats::SaveToDisk();
    if (textOverlayAudio !is null) {
        textOverlayAudio.StartFadeOutLoop();
        @textOverlayAudio = null;
    }
    if (g_api !is null) {
        g_api.Shutdown();
    }
    CheckUnhookAllRegisteredHooks();
    ClearAnimations();
    MagicSpectate::Unload();
    MainMenuBg::Unload();
}


vec2 g_MousePos;
uint lastMouseMove_NonUi;
void OnMouseMove(int x, int y) {
    g_MousePos = vec2(x, y);
    lastMouseMove_NonUi = Time::Now;
}

UI::InputBlocking OnMouseButton(bool down, int button, int x, int y) {
    g_MousePos = vec2(x, y);
    if (down) {
        bool lmb = button == 0;
        if (lmb) {
            if (DipsPPSettings::TestClick()) {
                return UI::InputBlocking::Block;
            }
        }
    }
    return UI::InputBlocking::DoNothing;
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (down) {
        if (key == VirtualKey::Escape) {
            if (MagicSpectate::CheckEscPress()) {
                return UI::InputBlocking::Block;
            }
        }
    }
    return UI::InputBlocking::DoNothing;
}


bool g_Active = false;
vec2 g_screen;
bool IsVehicleActionMap;


void RenderEarly() {
    IsVehicleActionMap = UI::CurrentActionMap() == "Vehicle";
    g_screen = vec2(Draw::GetWidth(), Draw::GetHeight());
    RenderEarlyInner();
    UpdateDownloads();
    if (g_Active || Minimap::updateMatrices) {
        Minimap::RenderEarly();
    }
    // when focusing ImgUI elements
    if (int(GetApp().InputPort.MouseVisibility) == 2) {
        g_MousePos = vec2(-1000);
    }
}

void RenderMenuMain() {
    if (!g_Active) return;
    DrawPluginMenuItem(true);
}

int g_TitleCollectionOutsideMapCount = 0;
int g_SubtitlesOutsideMapCount = 0;

void Render() {
    if (!G_Initialized) return;
#if DEV
    // RenderFireworkTest();
#endif
    bool drawAnywhereUI = S_ShowWhenUIHidden || UI::IsOverlayShown();
    bool drawAnywhereGame = S_ShowWhenUIHidden || UI::IsGameUIVisible();
    DownloadProgress::Draw();
    MaybeDrawLoadingScreen();
    Wizard::DrawWindow();
    Volume::RenderSubtitlesVolumeIfNotActive();
    // render Magic Spectate UI regardless of UI visibility, including warnings
    MagicSpectate::Render();
    if (S_BlockCam7Drivable) BlockCam7Drivable::Render();
    if (drawAnywhereUI) {
        MainUI::Render();
    }
    if (g_Active) {
        OnFinish::Render();
        GreenTimer::Render(drawAnywhereGame);
        HUD::Render(PS::viewedPlayer, drawAnywhereGame);
        RenderAnimations(drawAnywhereGame);
        RenderTextOveralys(drawAnywhereGame);
        RenderSubtitles(drawAnywhereGame);
        Minimap::Render(drawAnywhereGame);
        DipsPPSettings::RenderButton(drawAnywhereGame);
        RenderTitleScreenAnims(drawAnywhereGame);
        MainMenuBg::ClearRefs();
    } else {
        if (g_TitleCollectionOutsideMapCount > 0) {
            RenderTitleScreenAnims(true);
        }
        if (g_SubtitlesOutsideMapCount > 0) {
            RenderSubtitles(true);
        }
        if (S_EnableMainMenuPromoBg && IsInMainMenu()) {
            MainMenuBg::Update();
        } else {
            MainMenuBg::ClearRefs();
        }
    }
    RenderDebugWindow();
}

bool IsInMainMenu() {
    auto switcher = GetApp().Switcher;
    if (switcher.ModuleStack.Length == 0) return false;
    return cast<CTrackManiaMenus>(switcher.ModuleStack[0]) !is null;
}

#if DEV
[Setting hidden]
bool S_DisableUiInEditor = true;
#else
const bool S_DisableUiInEditor = true;
#endif

bool IsInEditor = true;
// requires game restart so only need to set once.
const float UI_SCALE = UI::GetScale();

bool RenderEarlyInner() {
    if (!G_Initialized) return false;
    auto app = GetApp();
    IsInEditor = app.Editor !is null;
    if (!IsInEditor) {
        CurrMap::CheckMapChange(app.RootMap);
    }
    bool wasActive = g_Active;
    // calling Inactive sets g_Active to false
    if (!S_Enabled) return Inactive(wasActive);
    if (app.RootMap is null) return Inactive(wasActive);
    if (app.CurrentPlayground is null) return Inactive(wasActive);
    if (app.CurrentPlayground.GameTerminals.Length == 0) return Inactive(wasActive);
    if (app.CurrentPlayground.GameTerminals[0].ControlledPlayer is null) return Inactive(wasActive);
    if (app.CurrentPlayground.UIConfigs.Length == 0) return Inactive(wasActive);
#if DEV
    if (app.Editor !is null && S_DisableUiInEditor) return Inactive(wasActive);
#else
    if (app.Editor !is null) return Inactive(wasActive);
#endif
    // if (!GoodUISequence(app.CurrentPlayground.UIConfigs[0].UISequence)) return Inactive(wasActive);
    bool matchDd2 = MatchDD2::MapMatchesDD2Uid(app.RootMap);
    // ! uncomment this to enable map UID check
    if (!(matchDd2 || (g_CustomMap !is null && g_CustomMap.IsEnabled))) return Inactive(wasActive);
    if (!wasActive) EmitGoingActive(true);
    g_Active = true;
    PS::UpdatePlayers();
    BlockCam7Drivable::Update();
    if (PS::localPlayer !is null) {
        PS::localPlayer.UpdateFinishCheck(app.CurrentPlayground.UIConfigs[0].UISequence);
    }
    return true;
}


bool GoodUISequence(CGamePlaygroundUIConfig::EUISequence seq) {
    return seq == CGamePlaygroundUIConfig::EUISequence::Playing
        || seq == CGamePlaygroundUIConfig::EUISequence::Finish;
}


void RenderMenu() {
    DrawPluginMenuItem();
    return;
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
    // if (UI::MenuItem(PluginName + ": Activate for this map")) {
    //     auto map = GetApp().RootMap;
    //     if (map is null) {
    //         NotifyError("No map found");
    //     } else {
    //         S_ActiveForMapUids = map.EdChallengeId;
    //     }
    // }
    // if (UI::MenuItem(PluginName + ": Deactivate for this map")) {
    //     S_ActiveForMapUids = "";
    // }
}

[Setting hidden]
bool g_ShowFalls = true;



void RenderSubtitles(bool doDraw) {
    RenderSubtitleAnims(doDraw);
}

void RenderTextOveralys(bool doDraw) {
    if (textOverlayAnims.Length == 0) return;
    for (uint i = 0; i < textOverlayAnims.Length; i++) {
        if (textOverlayAnims[i].Update()) {
            if (doDraw) textOverlayAnims[i].Draw();
        } else {
            dev_trace('removed text overlay anim at ' + i);
            textOverlayAnims[i].OnEndAnim();
            textOverlayAnims.RemoveAt(i);
            i--;
        }
    }
}

void RenderSubtitleAnims(bool doDraw) {
    if (subtitleAnims.Length == 0) return;
    if (subtitleAnims[0].Update()) {
        if (doDraw) subtitleAnims[0].Draw();
    } else {
        dev_trace("removing subtitle at 0");
        subtitleAnims[0].OnEndAnim();
        subtitleAnims.RemoveAt(0);
        if (g_SubtitlesOutsideMapCount > 0) {
            g_SubtitlesOutsideMapCount--;
        }
    }
    // for (uint i = 0; i < subtitleAnims.Length; i++) {
    //     if (subtitleAnims[i].Update()) {
    //         subtitleAnims[i].Draw();
    //     } else {
    //         subtitleAnims[i].OnEndAnim();
    //         subtitleAnims.RemoveAt(i);
    //         i--;
    //     }
    // }
}

void RenderTitleScreenAnims(bool doDraw) {
    if (titleScreenAnimations.Length == 0) return;
    if (titleScreenAnimations[0].Update()) {
        if (doDraw) titleScreenAnimations[0].Draw();
    } else {
        titleScreenAnimations[0].OnEndAnim();
        trace("Removing title anim: " + titleScreenAnimations[0].ToString());
        titleScreenAnimations.RemoveAt(0);
        if (g_TitleCollectionOutsideMapCount > 0) {
            g_TitleCollectionOutsideMapCount--;
        }
    }
    // for (uint i = 0; i < titleScreenAnimations.Length; i++) {
    //     // titleScreenAnimations[i].Draw();
    // }
}


void RenderAnimations(bool doDraw) {
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
            if (doDraw) {
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
            }
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
    // hack for when loading plugin
    if (dt > 500) {
        dt = 50;
    }
    g_DT = dt;
}


vec2 SmoothLerp(vec2 from, vec2 to, float t) {
    // drawAtWorldPos = Math::Lerp(lastDrawWorldPos, drawAtWorldPos, 1. - Math::Exp(animLambda * lastDt * 0.001));
    // animLambda: more negative => faster movement
    return Math::Lerp(from, to, 1. - Math::Exp(-6.0 * g_DT * 0.001));
}
float SmoothLerp(float from, float to) {
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
    startnew(MTWatcherForMap);
    startnew(CountTimeInMap);
    startnew(Signs3d::SignsOnGoingActive);
}

void CountTimeInMap() {
    auto app = GetApp();
    auto idVal = GetMapMwIdVal(app.RootMap);
    if (idVal == 0) {
        Dev_Notify("CountTimeInMap: idVal is 0");
        warn("CountTimeInMap: idVal is 0");
        return;
    }
    auto last = Time::Now;
    uint delta;
    while (g_Active) {
        yield();
        delta = Time::Now - last;
        Stats::LogTimeInMapMs(delta);
        last += delta;
    }
}

uint lastReportedRespawn;
void EmitOnPlayerRespawn(PlayerState@ ps) {
    if (ps.isLocal) {
        if (Time::Now - lastReportedRespawn > 1000 && ps.lastRaceTime < 999999999) {
            // trace("OnPlayerRespawn: " + ps.lastRaceTime);
            lastReportedRespawn = Time::Now;
            Stats::LogRestart(ps.lastRaceTime);
        }
    }
    if (ps.isViewed) {
        TitleGag::OnPlayerRespawn();
    }
}



uint g_LocalPlayerMwId = -1;

void AwaitLocalPlayerMwId() {
    while (g_LocalPlayerMwId == -1) {
        g_LocalPlayerMwId = GetLocalPlayerMwId();
        if (g_LocalPlayerMwId == -1) yield();
        else break;
    }
    // for (uint i = 0; i < PS::players.Length; i++) {
    //     PS::players[i].CheckUpdateIsLocal();
    // }
}

string _LocalPlayerLogin;

uint GetLocalPlayerMwId() {
    auto app = GetApp();
    if (app.LocalPlayerInfo is null) return -1;
    _LocalPlayerLogin = app.LocalPlayerInfo.Id.GetName();
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



void Notify(const string &in msg, int time = 5000) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, time);
    print("Notified: " + msg);
}
void Dev_Notify(const string &in msg) {
#if DEV
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    print("Notified: " + msg);
#endif
}

void NotifySuccess(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg, vec4(.4, .7, .1, .3), 10000);
    print("Notified Success: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

dictionary warnDebounce;
void NotifyWarningDebounce(const string &in msg, uint ms) {
    warn(msg);
    bool showWarn = !warnDebounce.Exists(msg) || Time::Now - uint(warnDebounce[msg]) > ms;
    if (showWarn) {
        UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
        warnDebounce[msg] = Time::Now;
    }
}


void dev_trace(const string &in msg) {
#if DEV
    trace(msg);
#endif
}


void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::SetNextWindowSize(400, 0, UI::Cond::Appearing);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
    }
}




void RNGExtraLoop() {
    float r;
    while (true) {
        r = Math::Rand(0.0, 1.0);
        sleep(Time::Now % 1000 + 500 * r);
    }
}
