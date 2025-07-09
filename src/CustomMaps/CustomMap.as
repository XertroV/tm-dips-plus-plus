CustomMap@ g_CustomMap;

void CustomMap_SetOnNewCustomMap(CustomMap@ map) {
    @g_CustomMap = map;
}

class CustomMap : WithMapOverview, WithLeaderboard, WithMapLive {
    // main map
    bool isDD2;
    // main or cp versions
    bool isDD2Any;
    bool hasStats = false;
    bool useDD2Triggers;
    bool hasCustomData;
    MapStats@ stats;
    string mapComment;
    string mapName;
    MapCustomInfo::DipsSpec@ spec;
    string loadError;
    float[] floors;
    bool lastFloorEnd = false;
    string mapUid;
    uint mapMwId;
    TriggersMgr@ triggersMgr;
    Json::Value@ auxSpec;
    string[] voiceLineNames;

    CustomMap(CGameCtnChallenge@ map) {
        mapUid = map.Id.GetName();
        mapMwId = GetMwIdValue(mapUid);
        if (MapCustomInfo::ShouldActivateForMap(map)) {
            hasStats = true;
            @stats = GetMapStats(map);
            isDD2 = stats.isDD2;
            useDD2Triggers = stats.isDD2 || stats.isEzMap;
            map.MwAddRef();
            if (!useDD2Triggers) @triggersMgr = TriggersMgr();
            startnew(CoroutineFuncUserdata(LoadCustomMapData), map);
            startnew(CoroutineFunc(RunMapLoop));
            startnew(CoroutineFunc(this.CheckUpdateLeaderboard));
        } else {
            startnew(CoroutineFuncUserdata(CheckForUploadedMapData), array<string> = {mapUid});
        }
    }

    // used for access outside the map
    CustomMap(const string &in mapUid, const string &in mapName) {
        this.mapUid = mapUid;
        mapMwId = GetMwIdValue(mapUid);
        if (MapCustomInfo::ShouldActivateForMap(mapUid, "")) {
            @stats = GetMapStats(mapUid, mapName);
            isDD2 = stats.isDD2;
            isDD2Any = stats.isDD2Any;
            useDD2Triggers = stats.isDD2Any || stats.isEzMap;
            startnew(CoroutineFuncUserdata(CheckForUploadedMapData), array<string> = {mapUid});
        }
    }

    ~CustomMap() {

    }

    void TriggerCheck_Update() {
        if (triggersMgr !is null) {
            triggersMgr.TriggerCheck_Update();
        }
    }

    void RunMapLoop() {
        if (isDD2) return;

        // wait for spec to load
        while (CurrMap::IdIs(mapMwId) && spec is null) yield();
        if (spec is null) return;
        if (!spec.minClientPass) return;

        // auto app = GetApp();
        auto lastUpdate = Time::Now + 25000;
        uint updateCount = 0;
        while (CurrMap::IdIs(mapMwId)) {
            if (Time::Now - lastUpdate > 5000) {
                if (PS::viewedPlayer !is null && PS::viewedPlayer.isLocal && PS::viewedPlayer.raceTime > 1500 && !PS::viewedPlayer.isIdle) {
                    // 3 * 2000^2
                    if (PS::localPlayer.pos.LengthSquared() > 12000000.) lastUpdate = Time::Now;
                    lastUpdate = Time::Now;
                    // skip first update in case of bad info
                    if (updateCount > 0) {
                        PushMessage(ReportMapCurrPosMsg(mapUid, PS::localPlayer.pos, PS::localPlayer.raceTime));
                    }
                    updateCount++;
                } else {
                    // check again in 1s
                    lastUpdate += 1000;
                }
            }
            yield();
        }
    }

    // for hardcoded heights and things
    bool get_IsEnabledNotDD2() {
        return hasCustomData && !useDD2Triggers;
    }

    bool get_IsEnabled() {
        return hasCustomData || useDD2Triggers;
    }

    // can yield; must call map.MwAddRef() before passing
    void LoadCustomMapData(ref@ mapRef) {
        auto map = cast<CGameCtnChallenge>(mapRef);
        if (map is null) return;
        hasCustomData = TryLoadingCustomData(map);
        map.MwRelease();
    }

    // can yield
    bool TryLoadingCustomData(CGameCtnChallenge@ map) {
        if (map is null) return false;
        @spec = MapCustomInfo::GetBuiltInInfo_Async(map.Id.Value);
        mapComment = map.Comments;
        mapName = Text::OpenplanetFormatCodes(map.MapName);
        if (spec is null) {
            @spec = MapCustomInfo::TryParse_Async(mapComment);
        }
        loadError = MapCustomInfo::lastParseFailReason;
        if (spec is null) {
            startnew(CoroutineFuncUserdata(CheckForUploadedMapData), array<string> = {stats.mapUid});
            return false;
        }
        if (!spec.minClientPass) {
            NotifyWarning("This map requires a newer version of Dips++.");
            return false;
        }
        if (spec.auxInfo !is null) {
            @auxSpec = spec.auxInfo.data;
            AuxiliaryAssets::Begin(mapName);
            AuxiliaryAssets::Load(auxSpec, spec.url);
            LoadAuxiliaryTriggers();
        }
        for (uint i = 0; i < spec.floors.Length; i++) {
            floors.InsertLast(spec.floors[i].height);
        }
        lastFloorEnd = spec.lastFloorEnd;
        return true;
    }

    void LoadAuxiliaryTriggers() {
        if (auxSpec is null) return;
        if (triggersMgr is null) {
            @triggersMgr = TriggersMgr();
        }

        if (auxSpec.HasKey("triggers")) {
            Json::Value@ triggers = auxSpec["triggers"];
            if (triggers.HasKey("triggers")) {
                Json::Value@ triggerList = triggers["triggers"];
                for (uint i = 0; i < triggerList.Length; i++) {
                    Json::Value@ triggerJson = triggerList[i];
                    if (triggerJson.HasKey("trigger")) {
                        Json::Value@ t = triggerJson["trigger"];
                        vec3 specPos = JsonToVec3(t["pos"]);
                        vec3 size = JsonToVec3(t["size"]);
                        vec3 pos = SpecPosToPos(specPos, size);
                        string name = string(t["name"]);
                        auto @options = name.Split("|");
                        // todo: use SpecialTextTrigger instead
                        triggersMgr.InsertTrigger(TextTrigger(pos, pos + size, name, options));
                    }
                }
            }
        }

        if (auxSpec.HasKey("voicelines")) {
            Json::Value@ voicelines = auxSpec["voicelines"];
            if (voicelines.HasKey("lines")) {
                Json::Value@ voicelineList = voicelines["lines"];
                for (uint i = 0; i < voicelineList.Length; i++) {
                    Json::Value@ vlJson = voicelineList[i];
                    AddVoiceLineTriggerJson(vlJson);
                    // if (vlJson.HasKey("trigger")) {
                    //     Json::Value@ t = vlJson["trigger"];
                    //     vec3 specPos = JsonToVec3(t["pos"]);
                    //     vec3 size = JsonToVec3(t["size"]);
                    //     vec3 pos = SpecPosToPos(specPos, size);
                    //     string name = string(t["name"]);
                    //     string file = string(vlJson["file"]);

                    //     string subtitles = "";
                    //     JsonX::SafeGetString(vlJson, "subtitles", subtitles);

                    //     string imageAsset = vlJson.HasKey("imageAsset") ? string(vlJson["imageAsset"]) : "";
                    //     // todo: probably don't need to use a new trigger.
                    //     triggersMgr.InsertTrigger(VoiceLineTrigger(pos, pos + size, name, file, subtitles, imageAsset));
                    // }
                }
            }
        }
    }

    void AddVoiceLineTriggerJson(Json::Value@ vlJson) {
        if (vlJson is null) return;
        string file;
        Json::Value@ trigger;
        if (!JsonX::SafeGetString(vlJson, "file", file)) {
            NotifyWarning("VoiceLineTrigger JSON missing 'file' key: " + Json::Write(vlJson));
            return;
        }
        @trigger = JsonX::SafeGetJson(vlJson, "trigger");
        if (trigger is null) {
            NotifyWarning("VoiceLineTrigger JSON missing 'trigger' key: " + Json::Write(vlJson));
            return;
        }
        if (file.Length == 0) {
            warn("VoiceLineTrigger JSON has empty 'file' key: " + Json::Write(vlJson));
            return;
        }
        string subtitles = "";
        if (!JsonX::SafeGetString(vlJson, "subtitles", subtitles)) {
            NotifyWarning("VoiceLineTrigger JSON missing 'subtitles' key: " + Json::Write(vlJson));
            return;
        }
        vec3 specPos, size, pos;
        try {
            specPos = JsonToVec3(trigger["pos"]);
            size = JsonToVec3(trigger["size"]);
            pos = SpecPosToPos(specPos, size);
        } catch {
            NotifyWarning("VoiceLineTrigger JSON has invalid 'pos' or 'size' key: " + Json::Write(trigger));
            NotifyWarning(getExceptionInfo());
            return;
        }

        string name;
        if (!JsonX::SafeGetString(trigger, "name", name)) {
            NotifyWarning("VoiceLineTrigger JSON missing 'name' key: " + Json::Write(trigger));
            return;
        }

        string imageAsset;
        JsonX::SafeGetString(vlJson, "imageAsset", imageAsset);
        triggersMgr.InsertTrigger(VoiceLineTrigger(pos, pos + size, name, file, subtitles, imageAsset));
        voiceLineNames.InsertLast(name);
    }

    bool WasCustomAssetDownloadDeclined() {
        if (auxSpec is null) return false;
        return AuxiliaryAssets::DidUserDecline();
    }

    void DrawMapTabs() {
        if (WasCustomAssetDownloadDeclined()) {
            UI::AlignTextToFramePadding();
            UI::Text("Map Assets Download Declined");
            UI::SameLine();
            if (UI::Button("Show Download Prompt")) {
                AuxiliaryAssets::ShowPrompt();
            }
            UI::Separator();
        }
        UI::BeginTabBar("cmtabs" + mapUid);
        if (UI::BeginTabItem("Stats")) {
            CheckUpdateMapOverview();
            DrawMapOverviewUI();
            if (stats !is null) {
                stats.DrawStatsUI();
            } else {
                UI::Text("Stats Missing! :(");
            }
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Leaderboard")) {
            this.DrawLeaderboard();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Live")) {
            this.DrawLiveUI();
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }

    void RenderDebugTriggers() {
        if (triggersMgr is null) return;
        triggersMgr.RenderDebugTriggers();
    }
}

const string MapInfosUploadedURL = "https://assets.xk.io/d++maps/";

void CheckForUploadedMapData(ref@ data) {
    auto mapUid = cast<string[]>(data)[0];
    auto url = MapInfosUploadedURL + mapUid + ".txt";
    trace('CheckForUploadedMapData: ' + mapUid + ' from ' + url);
    Net::HttpRequest@ req = Net::HttpGet(url);
    while (!req.Finished()) {
        yield();
    }
    auto status = req.ResponseCode();
    trace('CheckForUploadedMapData: ' + mapUid + ' status ' + status);
    if (status < 200 || status > 299) {
        // error
        if (status != 404) warn("Failed to load map data from " + url + " - status " + status + " response: " + req.String());
        return;
    }
    MapCustomInfo::AddNewMapComment(mapUid, req.String());
    trace('found and added map data for ' + mapUid + ' from ' + url);
    CurrMap::RecheckMap();
}

vec3 SpecPosToPos(vec3 specPos, vec3 size) {
    // specPos is middle-XZ bottom-Y coords (where the car was when placing the box).
    // size is the full size of the box.
    return specPos - vec3(size.x / 2, 0, size.z / 2);
}

class TriggersMgr {
    DipsOT::OctTree@ octTree;
    GameTrigger@[] triggers;

    TriggersMgr(nat3 mapSize = nat3(48, 255, 48)) {
        @octTree = DipsOT::OctTree(Nat3ToVec3(mapSize));
    }

    void InsertTrigger(GameTrigger@ trigger) {
        if (octTree is null) return;
        if (trigger is null) return;
        octTree.Insert(trigger);
        triggers.InsertLast(trigger);
    }

    void TriggerCheck_Update() {
        if (octTree is null) return;
        auto @player = PS::viewedPlayer;
        if (player is null) return;
        if (lastSeq != CGamePlaygroundUIConfig::EUISequence::Playing) return;
        // don't trigger immediately after (re)spawn
        if (player.lastRespawn + 100 > Time::Now) return;
        auto t = cast<GameTrigger>(octTree.root.PointToDeepestRegion(player.pos));
        // global function and trigger checker/doer
        _TriggerCheck_Hit(t);
    }

    void RenderDebugTriggers() {
        for (uint i = 0; i < triggers.Length; i++) {
            if (triggers[i].Debug_NvgDrawTrigger()) {
                triggers[i].Debug_NvgDrawTriggerName();
            }
        }
    }
}


mixin class WithMapLive {
    uint lastLiveUpdate = 0;
    void CheckUpdateLive() {
        if (lastLiveUpdate + 30000 < Time::Now) {
            lastLiveUpdate = Time::Now;
            PushMessage(GetMapLiveMsg(mapUid));
        }
    }

    void SetLivePlayersFromJson(Json::Value@ j) {
        if (!j.HasKey("uid") || mapUid != string(j["uid"])) { warn("Live got unexpected map uid: " + Json::Write(j["uid"])); return; }
        auto arr = j['players'];
        auto nbPlayers = arr.Length;
        while (mapLive.Length < nbPlayers) {
            mapLive.InsertLast(LBEntry());
        }
        for (uint i = 0; i < nbPlayers; i++) {
            mapLive[i].SetFromJson(arr[i]);
        }
    }

    LBEntry@[] mapLive = {};

    void DrawLiveUI() {
        int nbLive = mapLive.Length;
        CheckUpdateLive();
        DrawCenteredText("Live Heights", f_DroidBigger);
        DrawCenteredText("# Players: " + nbLive, f_DroidBig);
        if (nbLive == 0) return;
        if (UI::BeginChild("Live", vec2(0, 0), false, UI::WindowFlags::AlwaysVerticalScrollbar)) {
            if (UI::BeginTable('livtabel', 3, UI::TableFlags::SizingStretchSame)) {
                UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 80. * UI_SCALE);
                UI::TableSetupColumn("Height (m)", UI::TableColumnFlags::WidthFixed, 100. * UI_SCALE);
                UI::TableSetupColumn("Player");
                // UI::TableSetupColumn("Time");
                UI::ListClipper clip(nbLive);
                LBEntry@ item;
                while (clip.Step()) {
                    for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                        UI::PushID(i);
                        UI::TableNextRow();
                        @item = mapLive[i];
                        UI::TableNextColumn();
                        UI::Text(tostring(i + 1) + ".");
                        UI::TableNextColumn();
                        UI::Text(Text::Format("%.04f m", item.height));
                        UI::TableNextColumn();
                        UI::Text(item.name);
                        // UI::Text(Text::Format("%.02f s", item.ts));
                        UI::PopID();
                    }
                }
                UI::EndTable();
            }
        }
        UI::EndChild();
    }
}


mixin class WithMapOverview {
    uint lastMapOverviewUpdate = 0;
    // update at most once per minute
    void CheckUpdateMapOverview() {
        if (lastMapOverviewUpdate + 60000 < Time::Now) {
            lastMapOverviewUpdate = Time::Now;
            PushMessage(GetMapOverviewMsg(mapUid));
        }
    }

    void SetOverviewFromJson(Json::Value@ j) {
        if (!j.HasKey("uid") || mapUid != string(j["uid"])) { warn("Overview got unexpected map uid: " + Json::Write(j["uid"])); return; }
        nb_players_on_lb = j["nb_players_on_lb"];
        nb_playing_now = j["nb_playing_now"];
    }

    int nb_players_on_lb;
    int nb_playing_now;

    void DrawMapOverviewUI() {
        CheckUpdateMapOverview();
        DrawCenteredText("Map Overview", f_DroidBigger);
        UI::Columns(2);
        auto cSize = vec2(-1, ((UI::GetStyleVarVec2(UI::StyleVar::FramePadding).y + 20.) * UI_SCALE));
        UI::BeginChild("mov1", cSize);
        DrawCenteredText("Total Players: " + nb_players_on_lb, f_DroidBig);
        UI::EndChild();
        UI::NextColumn();
        UI::BeginChild("mov2", cSize);
        DrawCenteredText("Currently Climbing: " + nb_playing_now, f_DroidBig);
        UI::EndChild();
        UI::Columns(1);
        UI::Separator();
    }
}


mixin class WithLeaderboard {

    LBEntry@ myRank = LBEntry();

    dictionary pbCache;
    dictionary wsidToPlayerName;
    dictionary colorCache;

    void SetRankFromJson(Json::Value@ j) {
        if (!j.HasKey("uid") || mapUid != string(j["uid"])) { warn("PB got unexpected map uid: " + Json::Write(j["uid"])); return; }
        if (!j.HasKey("r")) { warn("PB missing r key"); return; }
        auto r = j["r"];
        if (r.GetType() != Json::Type::Object) return;
        if (PS::localPlayer !is null && PS::localPlayer.playerWsid == string(r["wsid"])) {
            myRank.SetFromJson(r);
            @pbCache[myRank.name] = myRank;
        } else {
            auto name = r["name"];
            if (pbCache.Exists(name)) {
                cast<LBEntry>(pbCache[name]).SetFromJson(r);
            } else {
                auto @entry = LBEntry();
                entry.SetFromJson(r);
                @pbCache[name] = entry;
            }
        }
    }

    dictionary lastPlayerUpdateTimes;
    void CheckUpdatePlayersHeight(const string &in login) {
        if (lastPlayerUpdateTimes.Exists(login)) {
            if (Time::Now - int(lastPlayerUpdateTimes[login]) < 30000) return;
        }
        lastPlayerUpdateTimes[login] = Time::Now;
        PushMessage(GetMapRankMsg(mapUid, LoginToWSID(login)));
    }

    LBEntry@ GetPlayersPBEntry(PlayerState@ p) {
        if (p is null) return null;
        CheckUpdatePlayersHeight(p.playerLogin);
        if (pbCache.Exists(p.playerName)) {
            return cast<LBEntry>(pbCache[p.playerName]);
        }
        return null;
    }

    float GetPlayersPBHeight(PlayerState@ p) {
        if (p is null) return -2.;
        auto pb = GetPlayersPBEntry(p);
        if (pb is null) return -1.;
        return pb.height;
    }

    uint lastLbUpdate = 0;
    uint lbLoadAtLeastNb = 605;
    // update at most once per minute
    void CheckUpdateLeaderboard() {
        if (lastLbUpdate + 60000 < Time::Now) {
            lastLbUpdate = Time::Now;
            PushMessage(GetMapMyRankMsg(mapUid));
            for (uint i = 0; i <= lbLoadAtLeastNb; i += 200) {
                PushMessage(GetMapLBMsg(mapUid, i, i + 205));
            }
        }
    }

    uint lastLbIncrSize = 0;
    void IncrLBLoadSize() {
        lastLbIncrSize = Time::Now;
        PushMessage(GetMapLBMsg(mapUid, lbLoadAtLeastNb, lbLoadAtLeastNb + 205));
        lbLoadAtLeastNb += 200;
    }

    bool reachedEndOfLB = false;

    void SetLBFromJson(Json::Value@ j) {
#if DEV
        // trace("SetLBFromJson: " + Json::Write(j));
#endif
        if (!j.HasKey("uid") || mapUid != string(j["uid"])) { warn("LB got unexpected map uid: " + Json::Write(j["uid"])); return; }
        auto arr = j["entries"];
        auto nbEntries = arr.Length;
        if (nbEntries == 0) {
            reachedEndOfLB = true;
            // warn("Got 0 entries for LB " + mapUid);
            return;
        }
        reachedEndOfLB = false;
        int rank = arr[0]["rank"];
        int maxRank = arr[nbEntries - 1]["rank"];
        maxRank = Math::Max(maxRank, rank + nbEntries - 1);
        while (maxRank > int(mapLB.Length)) {
            mapLB.InsertLast(LBEntry());
        }
        reachedEndOfLB = maxRank < int(lbLoadAtLeastNb);
        int lastRank = 0;
        for (uint i = 0; i < nbEntries; i++) {
            rank = int(arr[i]["rank"]);
            if (rank <= lastRank) {
                rank = lastRank + 1;
            }
            mapLB[rank - 1].SetFromJson(arr[i]);
            @pbCache[mapLB[rank - 1].name] = mapLB[rank - 1];
            wsidToPlayerName[mapLB[rank - 1].wsid] = mapLB[rank - 1].name;
            lastRank = rank;
            if ((i + 1) % 100 == 0) yield();
        }
    }


    LBEntry@[] mapLB = {};

    void DrawLeaderboard() {
        CheckUpdateLeaderboard();
        DrawCenteredText("Leaderboard", f_DroidBigger);
        auto len = int(Math::Min(mapLB.Length, 10));
        DrawCenteredText("Top " + len, f_DroidBigger);
        auto nbCols = len > 5 ? 2 : 1;
        auto startNewAt = nbCols == 1 ? len : (len + 1) / nbCols;
        UI::Columns(nbCols);
        auto cSize = vec2(-1, Math::Max(1.0, (UI::GetStyleVarVec2(UI::StyleVar::FramePadding).y + 20.) * startNewAt * UI_SCALE * 1.07));
        UI::BeginChild("lbc1", cSize);
        for (int i = 0; i < len; i++) {
            if (i == startNewAt) {
                UI::EndChild();
                UI::NextColumn();
                UI::BeginChild("lbc2", cSize);
            }
            auto @player = mapLB[i];
            if (player.name == "") {
                DrawCenteredText(tostring(i + 1) + ". ???", f_DroidBig);
            } else {
                DrawCenteredText(tostring(i + 1) + ". " + player.name + Text::Format(" - %.1f m", player.height), f_DroidBig);
            }
        }
        UI::EndChild();
        UI::Columns(1);
        UI::Separator();
        DrawCenteredText("My Rank", f_DroidBigger);
        DrawCenteredText(Text::Format("%d. ", myRank.rank) + Text::Format("%.4f m", myRank.height), f_DroidBig);
        UI::Separator();
        DrawCenteredText("Global Leaderboard", f_DroidBigger);
        if (UI::BeginChild("GlobalLeaderboard", vec2(0, 0), false, UI::WindowFlags::AlwaysVerticalScrollbar)) {
            if (UI::BeginTable('lbtabel', 3, UI::TableFlags::SizingStretchSame)) {
                UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 80. * UI_SCALE);
                UI::TableSetupColumn("Height (m)", UI::TableColumnFlags::WidthFixed, 100. * UI_SCALE);
                UI::TableSetupColumn("Player");
                UI::ListClipper clip(mapLB.Length);
                while (clip.Step()) {
                    for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                        UI::PushID(i);
                        UI::TableNextRow();
                        auto item = mapLB[i];
                        UI::TableNextColumn();
                        UI::Text(Text::Format("%d.", item.rank));
                        UI::TableNextColumn();
                        UI::Text(Text::Format("%.04f m", item.height));
                        UI::TableNextColumn();
                        UI::Text(item.name);
                        UI::PopID();
                    }
                }
                UI::EndTable();
            }
        }
        UI::BeginDisabled(mapLB.Length < lbLoadAtLeastNb || reachedEndOfLB);
        if (DrawCenteredButton("Load More", f_DroidBig)) {
            IncrLBLoadSize();
        }
        UI::EndDisabled();
        UI::EndChild();
    }
}
