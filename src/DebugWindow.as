[Setting hidden]
bool g_DebugOpen = false;

void RenderDebugWindow() {
#if DEV
#else
    return;
#endif
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
        if (UI::BeginTabItem("TimeOfDay")) {
            DrawTimeOfDayDebugTab();
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
        if (UI::BeginTabItem("API Packets")) {
            DrawAPIPacketsTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Net Packets")) {
            DrawPlayersNetPacketsTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Utils")) {
            DrawUtilsTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Statuses")) {
            DrawCurrentStatusesTab();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Class Debug")) {
            DrawClassDebugTab();
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


void DrawClassDebugTab() {
    ClsCount::RenderUI();
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

void DrawAPIPacketsTab() {
    if (g_api !is null) {
        UI::AlignTextToFramePadding();
        UI::Text("API Packet Counts");
        UI::Separator();
        uint c;
        UI::AlignTextToFramePadding();
        UI::Text("Recv Counts");
        for (uint i = 0; i < g_api.recvCount.Length; i++) {
            c = g_api.recvCount[i];
            if (c == 0) continue;
            UI::Text("[" + tostring(MessageResponseTypes(i)) + "]: " + c);
        }
        UI::AlignTextToFramePadding();
        UI::Text("Sent Counts");
        for (uint i = 0; i < g_api.sendCount.Length; i++) {
            c = g_api.sendCount[i];
            if (c == 0) continue;
            UI::Text("[" + tostring(MessageRequestTypes(i)) + "]: " + c);
        }
    }

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
        for (int i = 0; i < int(PS::vehicleIdToPlayers.Length); i++) {
            if (PS::vehicleIdToPlayers[i] is null) continue;
            PS::vehicleIdToPlayers[i].DrawDebugTree(i);
            count++;
        }
        CopiableLabeledValue("Nb Non-null", "" + count);
        UI::TreePop();
    }
    if (UI::TreeNode("Players")) {
        UI::Text("Count: " + PS::players.Length);
        for (int i = 0; i < int(PS::players.Length); i++) {
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
    CopiableLabeledValue("GC::GetOffset()", '' + GC::GetOffset());
    // dev_trace("GC::GetInfo()");
    CopiableLabeledValue("GC::GetInfo()", GC::GetInfo());
    // dev_trace("MI::GetPtr()");
    CopiableLabeledValue("MI::GetPtr()", Text::FormatPointer(MI::GetPtr(GetApp().GameScene)));
    // dev_trace("MI::GetLen()");
    CopiableLabeledValue("MI::GetLen()", Text::FormatPointer(MI::GetLen(GetApp().GameScene)));
    // dev_trace("MI::GetInfo()");
    CopiableLabeledValue("MI::GetInfo()", Text::FormatPointer(MI::GetInfo()));
    // dev_trace("done");
}


string m_UtilWsidConv = "";
void DrawUtilsTab() {
    m_UtilWsidConv = UI::InputTextMultiline("WSIDs", m_UtilWsidConv);
    if (UI::Button("Convert")) {
        auto wsids = m_UtilWsidConv.Split("\n");
        m_UtilWsidConv = "";
        for (uint i = 0; i < wsids.Length; i++) {
            auto wsid = wsids[i].Trim();
            if (wsid.Length == 0) continue;
            wsids[i] = WSIDToLogin(wsid);
            m_UtilWsidConv += wsids[i] + "\n";
        }
    }
}

string WSIDToLogin(const string &in wsid) {
    try {
        auto hex = string::Join(wsid.Split("-"), "");
        auto buf = HexToBuffer(hex);
        return buf.ReadToBase64(buf.GetSize(), true);
    } catch {
        warn("WSID failed to convert: " + wsid);
        return wsid;
    }
}


string LoginToWSID(const string &in login) {
    try {
        auto buf = MemoryBuffer();
        buf.WriteFromBase64(login, true);
        auto hex = BufferToHex(buf);
        return hex.SubStr(0, 8)
            + "-" + hex.SubStr(8, 4)
            + "-" + hex.SubStr(12, 4)
            + "-" + hex.SubStr(16, 4)
            + "-" + hex.SubStr(20)
            ;
    } catch {
        warn("Login failed to convert: " + login);
        return login;
    }
}

string BufferToHex(MemoryBuffer@ buf) {
    buf.Seek(0);
    auto size = buf.GetSize();
    string ret;
    for (uint i = 0; i < size; i++) {
        ret += Uint8ToHex(buf.ReadUInt8());
    }
    return ret;
}

string Uint8ToHex(uint8 val) {
    return Uint4ToHex(val >> 4) + Uint4ToHex(val & 0xF);
}

string Uint4ToHex(uint8 val) {
    if (val > 0xF) throw('val out of range: ' + val);
    string ret = " ";
    if (val < 10) {
        ret[0] = val + 0x30;
    } else {
        // 0x61 = a
        ret[0] = val - 10 + 0x61;
    }
    return ret;
}

MemoryBuffer@ HexToBuffer(const string &in hex) {
    MemoryBuffer@ buf = MemoryBuffer();
    for (int i = 0; i < int(hex.Length); i += 2) {
        buf.Write(Hex2ToUint8(hex.SubStr(i, 2)));
    }
    buf.Seek(0);
    return buf;
}

uint8 Hex2ToUint8(const string &in hex) {
    return HexPairToUint8(hex[0], hex[1]);
}


uint8 HexPairToUint8(uint8 c1, uint8 c2) {
    return HexCharToUint8(c1) << 4 | HexCharToUint8(c2);
}

// values output in range 0 to 15 inclusive
uint8 HexCharToUint8(uint8 char) {
    if (char < 0x30 || (char > 0x39 && char < 0x61) || char > 0x66) throw('char out of range: ' + char);
    if (char < 0x40) return char - 0x30;
    return char - 0x61 + 10;
}





float m_tod_azumith = Math::PI;
float m_tod_elevation = Math::PI;

void DrawTimeOfDayDebugTab() {
    vec2 pre_ae = vec2(m_tod_azumith, m_tod_elevation);
    m_tod_azumith = UI::SliderFloat("Azumith", pre_ae.x, 0, TAU);
    m_tod_elevation = UI::SliderFloat("Elevation", pre_ae.y, 0, TAU);
    if (m_tod_azumith != pre_ae.x || m_tod_elevation != pre_ae.y) {
        SetTimeOfDay::SetSunAngle(m_tod_azumith, m_tod_elevation);
    }
}
