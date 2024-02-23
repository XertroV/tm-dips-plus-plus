[Setting hidden]
bool g_DebugOpen = false;

void RenderDebugWindow() {
    if (UI::Begin(PluginName + ": Debug Window", g_DebugOpen, UI::WindowFlags::None)) {
        UI::BeginTabBar("DebugTabBar");
        if (UI::BeginTabItem("Players and Vehicles")) {
            DrawPlayersAndVehiclesTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Players From Net Packets")) {
            DrawPlayersNetPacketsTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Current Statuses")) {
            DrawCurrentStatusesTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Animations")) {
            DrawAnimationsTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Offsets")) {
            DrawOffsetsTab();
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }
    UI::End();
}

string GetNbPlayers() {
    CSmArenaClient@ cp;
    try {
        auto app = GetApp();
        @cp = cast<CSmArenaClient>(app.CurrentPlayground);
        return tostring(cp.Players.Length);
    } catch {
        return getExceptionInfo();
    }
}

void DrawAnimationsTab() {
    UI::Text("NbPlayers: " + GetNbPlayers());
    if (UI::TreeNode("statusAnimations")) {
        for (uint i = 0; i < statusAnimations.Length; i++) {
            auto anim = statusAnimations[i];
            if (anim is null) continue;
            UI::Text(anim.ToString(i));
        }
        UI::TreePop();
    }
    if (UI::TreeNode("titleScreenAnimations")) {
        for (uint i = 0; i < titleScreenAnimations.Length; i++) {
            auto anim = cast<FloorTitleGeneric>(titleScreenAnimations[i]);
            if (anim is null) continue;
            UI::Text(anim.ToString(i));
            anim.DebugSlider();
        }
        UI::TreePop();
    }
    UI::Separator();
    if (UI::Button("Add Test Animation")) {
        auto size = vec2(g_screen.x, g_screen.y * .3);
        auto pos = vec2(0, g_screen.y * .1);
        // titleScreenAnimations.InsertLast(FloorTitleGeneric("Floor 00 - SparklingW", pos, size));
        titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null, null));
        titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null, null));
        titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null, null));
        titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null, null));
        titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null, null));
        titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null, null));
    }
}


void DrawCurrentStatusesTab() {
    PlayerState@[] flying;
    PlayerState@[] falling;

    for (uint i = 0; i < PS::players.Length; i++) {
        auto player = PS::players[i];
        if (player is null) continue;
        if (player.isFlying) {
            flying.InsertLast(player);
        }
        if (player.isFalling) {
            falling.InsertLast(player);
        }
    }

    UI::Columns(2, "CurrentStatusesColumns");
    UI::Text("Flying: " + flying.Length);
    for (uint i = 0; i < flying.Length; i++) {
        UI::Text(flying[i].playerName);
    }
    UI::NextColumn();
    UI::Text("Falling: " + falling.Length);
    for (uint i = 0; i < falling.Length; i++) {
        UI::Text(falling[i].playerName + ", " + falling[i].FallYDistance());
    }
    UI::Columns(1);
}

void DrawPlayersNetPacketsTab() {
    if (UI::TreeNode("NetPackets")) {
        for (uint i = 0; i < PS::players.Length; i++) {
            auto p = PS::players[i];
            if (p is null) continue;
            p.DrawDebugTree(i);
            p.DrawDebugTree_Player(i);
        }
        UI::TreePop();
    }

    auto app = GetApp();
    CSmArenaClient@ cp = cast<CSmArenaClient>(app.CurrentPlayground);
    if (cp is null) return;
    auto arean_iface_mgr = cp.ArenaInterface;
    if (arean_iface_mgr is null) return;
    Dev::SetOffset(arean_iface_mgr, 0x12c, uint8(0));
}

void DrawPlayersAndVehiclesTab() {
    CopiableLabeledValue("Active", tostring(g_Active));
    CopiableLabeledValue("vehicleIdToPlayers.Length", tostring(PS::vehicleIdToPlayers.Length) + " / " + Text::Format("0x%x", PS::vehicleIdToPlayers.Length));
    CopiableLabeledValue("Nb Players", tostring(PS::players.Length));
    CopiableLabeledValue("Nb Vehicles", tostring(PS::debug_NbVisStates));
    CopiableLabeledValue("Nb Player Vehicles", tostring(PS::nbPlayerVisStates));
    if (UI::TreeNode("VehicleIdToPlayers")) {
        uint count = 0;
        for (int i = 0; i < PS::vehicleIdToPlayers.Length; i++) {
            if (PS::vehicleIdToPlayers[i] is null) continue;
            PS::vehicleIdToPlayers[i].DrawDebugTree(i);
            count++;
        }
        CopiableLabeledValue("Nb Non-null", "" + count);
        UI::TreePop();
    }
    if (UI::TreeNode("Players")) {
        UI::Text("Count: " + PS::players.Length);
        for (int i = 0; i < PS::players.Length; i++) {
            PS::players[i].DrawDebugTree(i);
        }
        UI::TreePop();
    }
}


void DrawOffsetsTab() {
    CopiableLabeledValue("O_CSmPlayer_NetPacketsBuf", Text::Format("0x%04x", O_CSmPlayer_NetPacketsBuf));
    CopiableLabeledValue("SZ_CSmPlayer_NetPacketsBufStruct", Text::Format("0x%04x", SZ_CSmPlayer_NetPacketsBufStruct));
    CopiableLabeledValue("LEN_CSmPlayer_NetPacketsBuf", Text::Format("0x%04x", LEN_CSmPlayer_NetPacketsBuf));
    CopiableLabeledValue("SZ_CSmPlayer_NetPacketsUpdatedBufEl", Text::Format("0x%04x", SZ_CSmPlayer_NetPacketsUpdatedBufEl));
    CopiableLabeledValue("O_CSmPlayer_NetPacketsUpdatedBuf", Text::Format("0x%04x", O_CSmPlayer_NetPacketsUpdatedBuf));
    CopiableLabeledValue("O_CSmPlayer_NetPacketsBuf_NextIx", Text::Format("0x%04x", O_CSmPlayer_NetPacketsBuf_NextIx));
}













/** Render function called every frame intended only for menu items in `UI`.
*/
void RenderMenu() {
    if (UI::MenuItem(PluginName + ": Show Falls On Left Side", "", g_ShowFalls)) {
        g_ShowFalls = !g_ShowFalls;
    }
    if (UI::MenuItem(PluginName + ": Debug Window", "", g_DebugOpen)) {
        g_DebugOpen = !g_DebugOpen;
    }
}

[Setting hidden]
bool g_ShowFalls = true;

/** Render function called every frame.
*/
void Render() {
    RenderTitleScreenAnims();
    RenderAnimations();

    if (g_DebugOpen) {
        RenderDebugWindow();
    }
}


void RenderTitleScreenAnims() {
    if (titleScreenAnimations.Length == 0) return;
    if (titleScreenAnimations[0].Update()) {
        titleScreenAnimations[0].Draw();
    } else {
        trace("Removing title anim: " + titleScreenAnimations[0].ToString());
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

    vec2 pos;
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
