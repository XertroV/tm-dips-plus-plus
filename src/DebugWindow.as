[Setting hidden]
bool g_DebugOpen = false;

void RenderDebugWindow() {
    if (!g_DebugOpen) return;
    if (UI::Begin(PluginName + ": Debug Window", g_DebugOpen, UI::WindowFlags::AlwaysVerticalScrollbar)) {
        UI::BeginTabBar("DebugTabBar", UI::TabBarFlags::FittingPolicyScroll);
        if (UI::BeginTabItem("Triggers")) {
            DrawTriggersTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Collections")) {
            DrawCollectionsTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Players")) {
            DrawPlayersAndVehiclesTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Animations")) {
            DrawAnimationsTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Minimap")) {
            DrawMinimapTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Net Packets")) {
            DrawPlayersNetPacketsTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Current Statuses")) {
            DrawCurrentStatusesTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Credits -------------")) {
            DrawCreditsTab();
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

void DrawCreditsTab() {
    if (UI::Button("Roll Credits")) {
        NotifyWarning("Credits: todo");
    }
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

void DrawCollectionsTab() {
    if (GLOBAL_TITLE_COLLECTION !is null && UI::TreeNode("Titles")) {
        for (uint i = 0; i < GLOBAL_TITLE_COLLECTION.items.Length; i++) {
            auto title = cast<TitleCollectionItem>(GLOBAL_TITLE_COLLECTION.items[i]);
            if (title is null) continue;
            title.DrawDebug();
        }
        UI::TreePop();
    }

    if (GLOBAL_GG_TITLE_COLLECTION !is null && UI::TreeNode("GG Titles")) {
        for (uint i = 0; i < GLOBAL_GG_TITLE_COLLECTION.items.Length; i++) {
            auto title = cast<TitleCollectionItem>(GLOBAL_GG_TITLE_COLLECTION.items[i]);
            if (title is null) continue;
            title.DrawDebug();
        }
        UI::TreePop();
    }
}

void DrawMinimapTab() {
    Minimap::DrawMinimapDebug();
}

void DrawAnimationsTab() {
    UI::Text("NbPlayers: " + GetNbPlayers());
    if (UI::TreeNode("textOverlayAnims")) {
        for (uint i = 0; i < textOverlayAnims.Length; i++) {
            auto anim = textOverlayAnims[i];
            if (anim is null) continue;
            UI::Text(anim.ToString(i));
        }
        UI::TreePop();
    }
    if (UI::TreeNode("subtitleAnims")) {
        for (uint i = 0; i < subtitleAnims.Length; i++) {
            auto anim = subtitleAnims[i];
            if (anim is null) continue;
            UI::Text(anim.ToString(i));
        }
        UI::TreePop();
    }
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
            auto animGeneric = titleScreenAnimations[i];
            UI::Text(animGeneric.ToString(i));
            auto anim = cast<FloorTitleGeneric>(titleScreenAnimations[i]);
            if (anim is null) continue;
            anim.DebugSlider();
        }
        UI::TreePop();
    }
    UI::Separator();
    // if (UI::Button("Add Test Animation")) {
    //     auto size = vec2(g_screen.x, g_screen.y * .3);
    //     auto pos = vec2(0, g_screen.y * .1);
    //     // titleScreenAnimations.InsertLast(FloorTitleGeneric("Floor 00 - SparklingW", pos, size));
    //     titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null));
    //     titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null));
    //     titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null));
    //     titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null));
    //     titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null));
    //     titleScreenAnimations.InsertLast(MainTitleScreenAnim("Deep Dip 2", "The Re-Dippening", null));
    // }
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
    CopiableLabeledValue("Map Bounds", Minimap::mapMinMax.ToString());
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
