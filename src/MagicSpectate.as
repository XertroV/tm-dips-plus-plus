[Setting hidden]
bool S_ClickMinimapToMagicSpectate = true;

[Setting hidden]
bool S_DrawInputsWhileMagicSpec = true;

[Setting hidden]
bool S_PauseTimerWhileSpectating = true;

#if DEPENDENCY_MLHOOK
const bool MAGIC_SPEC_ENABLED = true;

// This is particularly for NON-spectate mode (i.e., players while driving)
// It will allow them to spectate someone without killing their run.
namespace MagicSpectate {
    void Unload() {
        Reset();
        MLHook::UnregisterMLHooksAndRemoveInjectedML();
    }

    void Load() {
        trace("Registered ML Exec callback for Magic Spectator");
        MLHook::RegisterPlaygroundMLExecutionPointCallback(onMLExec);
        if (!IsMLHookEnabled()) {
            NotifyWarning("MLHook is disabled! Click to spectate may not work correctly.");
        }
    }

    void Reset() {
        @currentlySpectating = null;
    }

    void Render() {
        if (Time::Now - movementAlarmLastTime < 500) {
            _DrawMovementAlarm();
        }
        if (currentlySpectating !is null) {
            _DrawCurrentlySpectatingUI();
        } else if (Spectate::IsSpectator) {
            _DrawGameSpectatingUI();
        }
    }

    bool CheckEscPress() {
        if (currentlySpectating !is null) {
            Reset();
            return true;
        }
        return false;
    }

    bool IsActive() {
        return currentlySpectating !is null;
    }
    PlayerState@ GetTarget() {
        return currentlySpectating;
    }

    void SpectatePlayer(PlayerState@ player) {
        trace('Magic Spectate: ' + player.playerName + ' / ' + Text::Format("%08x", player.lastVehicleId));
        @currentlySpectating = player;
    }

    uint movementAlarmLastTime = 0;
    bool movementAlarm = false;
    PlayerState@ currentlySpectating;
    void onMLExec(ref@ _x) {
        movementAlarm = false;
        if (currentlySpectating is null) return;
        if (!g_Active) {
            dev_trace("magic spectate resetting: not active");
            Reset();
            return;
        }
        auto app = GetApp();
        if (app.GameScene is null || app.CurrentPlayground is null) {
            dev_trace("magic spectate resetting: game scene or curr pg null");
            Reset();
            return;
        }
        uint vehicleId = currentlySpectating.lastVehicleId;
        if (currentlySpectating.vehicle is null || currentlySpectating.vehicle.AsyncState is null) {
            NotifyWarning("Turn on opponents to use magic spectate. (Otherwise, this is a bug.)");
            Reset();
            return;
        }
        // do nothing if the vehicle id is invalid, it might become valid
        if (vehicleId == 0 || vehicleId & 0x0f000000 > 0x05000000) {
            // dev_trace("Bad vehicle id: " + Text::Format("%08x", vehicleId));
            return;
        }
        auto @player = PS::GetPlayerFromVehicleId(vehicleId);
        if (player is null) {
            dev_trace("magic spectate resetting: GetPlayerFromVehicleId null");
            Reset();
            return;
        }
        movementAlarm = PS::localPlayer.vel.LengthSquared() > (PS::localPlayer.isFlying ? 0.13 : 0.02);
        if (movementAlarm) {
            movementAlarmLastTime = Time::Now;
            Reset();
            return;
        }
        _SetCameraVisIdTarget(app, vehicleId);
    }

    void _SetCameraVisIdTarget(CGameCtnApp@ app, uint vehicleId) {
        if (app is null || app.GameScene is null || app.CurrentPlayground is null) {
            Reset();
            return;
        }
        if (vehicleId > 0 && vehicleId & 0x0FF00000 != 0x0FF00000) {
            CMwNod@ gamecam = Dev::GetOffsetNod(app, O_GAMESCENE + 0x10);
            // vehicle id targeted by the camera
            Dev::SetOffset(gamecam, 0x44, vehicleId);
        } else {
            dev_trace("magic spectate resetting: _SetCameraVisIdTarget bad vehicleId: " + Text::Format("%08x", vehicleId));
            Reset();
        }
    }


    void _DrawCurrentlySpectatingUI() {
        auto p = currentlySpectating;
        auto pad = SPEC_BG_PAD * Minimap::vScale;
        auto namePosCM = SPEC_NAME_POS * g_screen;
        string name = p.playerName;
        if (p.clubTag.Length > 0) {
            name = "["+StripFormatCodes(p.clubTag)+"] " + name;
        }
        // Draw name at same place as normal spectate name
        nvg::Reset();
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::FontFace(f_Nvg_ExoExtraBoldItalic);
        float fs = SPEC_NAME_HEIGHT * Minimap::vScale;
        nvg::FontSize(fs);
        nvg::BeginPath();
        vec2 bgSize = nvg::TextBounds(name) + pad * 2.;
        vec2 bgTL = namePosCM - bgSize / 2.;
        nvg::FillColor(cBlack85);
        nvg::RoundedRect(bgTL, bgSize, pad.x);
        nvg::Fill();
        nvg::StrokeColor((cWhite50 + p.color) / 2.);
        nvg::StrokeWidth(2.0);
        nvg::Stroke();
        nvg::BeginPath();
        DrawText(SPEC_NAME_POS * g_screen + vec2(0, fs * .1), name, (cWhite + p.color) / 2.);
        string twitchName = TwitchNames::GetTwitchName(p.playerWsid);
        if (twitchName.Length > 0) {
            DrawTwitchName(twitchName, fs, pad, true);
        }
        if (S_DrawInputsWhileMagicSpec) {
            if (S_ShowInputsWhenUIHidden || UI::IsGameUIVisible()) {
                MS_RenderInputs(p);
            }
        }
    }

    void MS_RenderInputs(PlayerState@ p) {
        if (p.vehicle is null) return;
        if (p.vehicle.AsyncState is null) return;
        auto inputsSize = vec2(S_InputsHeight * 2, S_InputsHeight) * g_screen.y;
        auto inputsPos = (g_screen - inputsSize) * vec2(S_InputsPosX, S_InputsPosY);
        inputsPos += inputsSize;
        nvg::Translate(inputsPos);
        Inputs::DrawInputs(p.vehicle.AsyncState, p.color, inputsSize);
        nvg::ResetTransform();
    }

    void _DrawMovementAlarm() {
            nvg::Reset();
            nvg::BeginPath();
            nvg::FontSize(50. * Minimap::vScale);
            nvg::FontFace(f_Nvg_ExoExtraBold);
            nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
            DrawTextWithStroke(vec2(.5, 0.69) * g_screen, "Movement!", cRed, 4. * Minimap::vScale);
    }

    void DrawMenu() {
        if (UI::BeginMenu("Magic Spectate")) {
            S_ClickMinimapToMagicSpectate = UI::Checkbox("Click Minimap to Magic Spectate", S_ClickMinimapToMagicSpectate);
            S_DrawInputsWhileMagicSpec = UI::Checkbox("Show Inputs While Magic Spectating", S_DrawInputsWhileMagicSpec);
            DrawInputsSettingsMenu();
            UI::EndMenu();
        }
    }
}

#else
const bool MAGIC_SPEC_ENABLED = false;
namespace MagicSpectate {
    void Unload() {}
    void Load() {}
    void Reset() {}
    void Render() {
        if (Spectate::IsSpectator) {
            _DrawGameSpectatingUI();
        }
    }
    void DrawMenu() {}
    void SpectatePlayer(PlayerState@ player) {}
    bool CheckEscPress() { return false; }
    bool IsActive() { return false; }
    PlayerState@ GetTarget() { return null; }
}
#endif


const uint16 O_GAMESCENE = GetOffset("CGameCtnApp", "GameScene");


namespace MagicSpectate {
    const float SPEC_NAME_HEIGHT = 50.;
    const vec2 SPEC_NAME_POS = vec2(.5, 0.8333333333333334);
    const vec2 SPEC_BG_PAD = vec2(18.);

    void _DrawGameSpectatingUI() {
        auto p = PS::viewedPlayer;
        if (p is null) return;
        string twitchName = TwitchNames::GetTwitchName(p.playerWsid);
        // if (twitchName.Length == 0) twitchName = "<< Unknown >>";
        float fs = 36. * Minimap::vScale;
        auto pad = SPEC_BG_PAD * Minimap::vScale;
        nvg::Reset();
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::FontFace(f_Nvg_ExoExtraBoldItalic);
        nvg::FontSize(fs);
        if (twitchName.Length > 0) {
            DrawTwitchName(twitchName, fs, pad, false);
        }
    }

    void DrawTwitchName(const string &in twitchName, float fs, vec2 pad, bool isMagicSpec) {
        vec4 rect();

        string label = Icons::Twitch + " " + twitchName;
        nvg::FontSize(fs);
        vec2 bounds = nvg::TextBounds(label);

        rect.y = 1240. * Minimap::vScale;
        if (isMagicSpec) {
            rect.y += 28. * Minimap::vScale;
            rect.w = 64. * Minimap::vScale;
        } else {
            rect.w = 64. * Minimap::vScale;
        }
        rect.z = bounds.x + pad.x * 2.;
        rect.x = 0.5 * g_screen.x - rect.z / 2.;


        vec2 textPos = rect.xy + rect.zw / 2. + vec2(0., fs * 0.1);

        nvg::BeginPath();

        if (isMagicSpec) {
            nvg::RoundedRect(rect.xy - pad * .5, rect.zw + pad, pad.x);
        } else {
            vec2 slantOff = vec2(6.0 * Minimap::vScale, 0.);
            nvg::MoveTo(rect.xy + slantOff);
            nvg::LineTo(rect.xy + slantOff + vec2(rect.z, 0));
            nvg::LineTo(rect.xy - slantOff + rect.zw);
            nvg::LineTo(rect.xy - slantOff + vec2(0., rect.w));
            nvg::LineTo(rect.xy + slantOff);
        }
        nvg::FillColor(cBlack85);
        nvg::Fill();

        nvg::BeginPath();
        DrawText(textPos, label, cTwitch);
    }
}


// This is for managing spectating more generally
namespace Spectate {
    void StopSpectating() {
        MagicSpectate::Reset();
        ServerStopSpectatingIfSpectator();
    }

    void SpectatePlayer(PlayerState@ p) {
        // deactivate if we're in proper spectator mode
        if (IsSpectator && MagicSpectate::IsActive()) {
            MagicSpectate::Reset();
        }
        // if we are driving
        bool areWeDriving = PS::localPlayer.playerScoreMwId == PS::viewedPlayer.playerScoreMwId;
        if (MAGIC_SPEC_ENABLED && !IsSpectator && ((MagicSpectate::IsActive() || areWeDriving))) {
            MagicSpectate::SpectatePlayer(p);
        } else {
            ServerSpectatePlayer(p);
        }
    }

    void ServerSpectatePlayer(PlayerState@ p) {
        auto net = GetApp().Network;
        auto api = net.PlaygroundClientScriptAPI;
        auto client = net.ClientManiaAppPlayground;
        api.SetSpectateTarget(p.playerLogin);
        // https://github.com/ezio416/tm-spectator-camera/blob/6a8f5180c90d37d15b830d238065fa7dab83b3cc/src/Main.as#L206
        client.ClientUI.Spectator_SetForcedTarget_Clear();
        api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
    }

    void ServerStopSpectatingIfSpectator() {
        auto api = GetApp().Network.PlaygroundClientScriptAPI;
        if (!api.IsSpectator) return;
        api.RequestSpectatorClient(false);
    }

    void ServerStartSpectatingIfNotSpectator() {
        auto api = GetApp().Network.PlaygroundClientScriptAPI;
        if (api.IsSpectator) return;
        api.RequestSpectatorClient(true);
    }

    bool get_IsSpectator() {
        return GetApp().Network.Spectator;
    }

    bool get_IsSpectatorOrMagicSpectator() {
        return MagicSpectate::IsActive() || IsSpectator;
    }
}



bool IsMLHookEnabled() {
    auto p = Meta::GetPluginFromSiteID(252);
    return p !is null && p.Enabled;
}
