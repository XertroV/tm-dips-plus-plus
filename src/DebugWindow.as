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

void DrawAPIPacketsTab() {
    if (g_api !is null && UI::TreeNode("API Packets")) {
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
        UI::TreePop();
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

MemoryBuffer@ HexToBuffer(const string &in hex) {
    MemoryBuffer@ buf = MemoryBuffer();
    for (int i = 0; i < hex.Length; i += 2) {
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


/*
ed14ac85-1252-4cc7-8efd-49cd72938f9d
e387f7d8-afb0-4bf6-bb29-868d1a62de3b
bd45204c-80f1-4809-b983-38b3f0ffc1ef
af30b7a1-fc37-485f-94bf-f00e39805d8c
537011f1-b461-468c-a07b-871894113aad
ce9e4eb6-be30-429c-9487-20ce620c2de8
c4d583af-15c4-4f6f-8188-a2b6aa0c5e09
803695f6-8319-4b8e-8c28-44856834fe3b
f37147a8-36f3-4c58-9577-bf0faff3aafa
82783a8b-5e20-44c1-8ae9-b2ac123b3c40
b05db0f8-d845-47d2-b0e5-795717038ac6
e3ff2309-bc24-414a-b9f1-81954236c34b
076d23a5-51a6-48aa-8d99-9d618cd13c93
0e386730-ea74-4e39-8cec-b26c6e7ebb83
3bb0d130-637d-46a6-9c19-87fe4bda3c52
e5a9863b-1844-4436-a8a8-cea583888f8b
bafa7673-0a7b-4d50-b31b-919d500ae7ff
02f1a7ff-69cd-4e9b-9165-631b32e4a51f
15d23e07-07ac-4093-bbfd-28d393daf0c0
5e9ff69c-476f-4b8f-842f-2f5452a1af8a
794a286c-44d9-4276-83ce-431cba7bab74
c10a0cb3-347b-48bd-8a72-f884690697bf
05477e79-25fd-48c2-84c7-e1621aa46517
49d08816-4262-431d-bd47-3777f224f61d
e07e9ea9-daa5-4496-9908-9680e35da02b
db3affaa-a69b-4c48-aa48-0d1216e257af
84505c99-31f7-461e-8e53-9214fe0a68f0
61f14e3f-396a-41a4-80f6-1b307dcbf922
fb678553-f730-442a-a035-dfc50f4a5b7b
5f9c2a43-593f-4e84-a64d-82319058dd3a
01fe5b11-5ada-48a0-9da7-367e153ac3ad
3d71524d-922d-4755-9f9a-86bd93cedbf9
296a893d-03f0-4fc9-91f8-5dfc56d3d710
f4f42e27-83c7-48bf-833f-f9d27904d127
da4642f9-6acf-43fe-88b6-b120ff1308ba
69011be3-bd22-4e99-bc62-a8f04b434674
d320a237-1b0a-4069-af83-f2c09fbf042e
2a9faa84-5928-4eeb-a000-b44f46a50530
5e9ff69c-476f-4b8f-842f-2f5452a1af8a
a98c34ef-5896-417b-bdfe-35c8ed25c4bc
02aacbd8-4cee-4106-8934-d82245952b22
142246
3f3c8b1f-157f-417f-bf94-b9cdb3716fa2
5d6b14db-4d41-47a4-93e2-36a3bf229f9b
c1299945-2692-42dd-b28d-03c32dea8768
b7fff609-319b-4fd0-813f-f47bf5ca8d16
 */
