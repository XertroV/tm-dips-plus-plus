[Setting hidden]
bool S_ClickMinimapToMagicSpectate = true;

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
        MLHook::RegisterPlaygroundMLExecutionPointCallback(onMLExec);
    }

    void Reset() {
        @currentlySpectating = null;
    }

    void Render() {
        if (Time::Now - movementAlarmLastTime < 500) {
            _DrawMovementAlarm();
        }
        if (currentlySpectating is null) return;
        _DrawCurrentlySpectatingUI();
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
        // do nothing if the vehicle id is invalid, it might become valid
        if (vehicleId == 0 || vehicleId & 0x0f000000 > 0x05000000) return;
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



    const float SPEC_NAME_HEIGHT = 50.;
    const vec2 SPEC_NAME_POS = vec2(.5, 0.8333333333333334);
    const vec2 SPEC_BG_PAD = vec2(18.);

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
        nvg::BeginPath();
        DrawText(SPEC_NAME_POS * g_screen + vec2(0, fs * .1), name, (cWhite + p.color) / 2.);
    }

    void _DrawMovementAlarm() {
            nvg::Reset();
            nvg::BeginPath();
            nvg::FontSize(50. * Minimap::vScale);
            nvg::FontFace(f_Nvg_ExoExtraBold);
            nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
            DrawTextWithStroke(vec2(.5, 0.69) * g_screen, "Movement!", cRed, 4. * Minimap::vScale);
            trace('drawing movement alarm');
    }

    void DrawMenu() {
        if (UI::BeginMenu("Spec")) {
            S_ClickMinimapToMagicSpectate = UI::Checkbox("Click Minimap to Magic Spectate", S_ClickMinimapToMagicSpectate);
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
    void Render() {}
    void DrawMenu() {}
    void SpectatePlayer(PlayerState@ player) {}
    bool CheckEscPress() { return false; }
    bool IsActive() { return false; }
    PlayerState@ GetTarget() { return null; }
}
#endif


const uint16 O_GAMESCENE = GetOffset("CGameCtnApp", "GameScene");





// This is for managing spectating more generally
namespace Spectate {
    void StopSpectating() {
        MagicSpectate::Reset();
        ServerStopSpectatingIfSpectator();
    }

    void SpectatePlayer(PlayerState@ p) {
        // if we are driving
        if (MagicSpectate::IsActive() || PS::localPlayer.playerScoreMwId == PS::viewedPlayer.playerScoreMwId) {
            MagicSpectate::SpectatePlayer(p);
        } else {
            ServerSpectatePlayer(p);
        }
    }

    void ServerSpectatePlayer(PlayerState@ p) {
        GetApp().Network.PlaygroundClientScriptAPI.SetSpectateTarget(p.playerLogin);
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
}
