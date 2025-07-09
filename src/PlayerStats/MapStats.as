// use GetMapStats instead of instantiating directly
class MapStats {
    string mapUid;
    string mapName;
    string jsonFile;
    bool isDD2 = false;
    bool isDD2Any = false;
    uint _mapMwId;

    uint64 msSpentInMap = 0;
    uint nbJumps = 0;
    uint nbFalls = 0;
    uint nbFloorsFallen = 0;
    uint[] floorVoiceLinesPlayed = {};
    uint[] reachedFloorCount = {};
    uint nbResets = 0;
    float pbHeight;
    int pbFloor = 0;
    float totalDistFallen;
    uint[] monumentTriggers = {};
    uint ggsTriggered = 0;
    uint titleGagsTriggered = 0;
    uint titleGagsSpecialTriggered = 0;
    uint byeByesTriggered = 0;
    Json::Value@ extra = Json::Object();
    uint lastPbSetTs = 0;
    int pbRaceTime = 0;
    vec3 pbPos = vec3();
    // local time, don't send to server
    uint lastPbSet = 0;
    uint lastInMap = Time::Stamp;
    // custom map voice lines
    Json::Value@ customVLsPlayed = Json::Object();

    MapStats(const string &in mapUid, const string &in name) {
        this.mapUid = mapUid;
        _mapMwId = GetMwIdValue(mapUid);
        this.mapName = Text::OpenplanetFormatCodes(name);
        AfterConstructor();
    }
    MapStats(CGameCtnChallenge@ map) {
        mapUid = map.MapInfo.MapUid;
        _mapMwId = map.Id.Value;
        mapName = Text::OpenplanetFormatCodes(map.MapInfo.Name);
        AfterConstructor();
    }

    protected void AfterConstructor() {
        isDD2Any = MatchDD2::VerifyIsDD2(mapUid);
        isDD2 = mapUid == DD2_MAP_UID;
        jsonFile = GetMapStatsFileName(mapUid);
        if (!IO::FileExists(jsonFile)) {
            InitJsonFile();
        } else {
            Json::Value@ j = Json::FromFile(jsonFile);
            LoadJsonFromFile(j);
        }
    }

    ~MapStats() {
        SaveToDisk();
    }

    void MapWatchLoop() {
        while (CurrMap::IdIs(_mapMwId)) {
            yield();
        }
        SaveToDisk();
    }

    void SaveToDisk() {
        Json::ToFile(jsonFile, this.ToJson());
    }

    void SaveToBackupStatsFile() {
        Json::ToFile(jsonFile + ".bak", this.ToJson());
    }

    void LoadJsonFromFile(Json::Value@ j) {
        dev_trace("loading stats: " + Json::Write(j));
        msSpentInMap = uint(j["seconds_spent_in_map"]) * 1000;
        nbJumps = j["nb_jumps"];
        nbFalls = j["nb_falls"];
        nbFloorsFallen = j["nb_floors_fallen"];
        lastPbSetTs = j["last_pb_set_ts"];
        totalDistFallen = j["total_dist_fallen"];
        pbHeight = j["pb_height"];
        pbFloor = HeightToFloor(g_CustomMap, pbHeight);
        nbResets = j["nb_resets"];
        ggsTriggered = j["ggs_triggered"];
        titleGagsTriggered = j["title_gags_triggered"];
        titleGagsSpecialTriggered = j["title_gags_special_triggered"];
        byeByesTriggered = j["bye_byes_triggered"];
        monumentTriggers = JsonToUintArray(j["monument_triggers"]);
        reachedFloorCount = JsonToUintArray(j["reached_floor_count"]);
        floorVoiceLinesPlayed = JsonToUintArray(j["floor_voice_lines_played"]);
        lastInMap = j.Get("last_in_map", 0);
        pbRaceTime = j.Get("pb_race_time", pbRaceTime);
        if (j.HasKey("pb_pos")) {
            pbPos = JsonToVec3(j["pb_pos"]);
        }
        if (j.HasKey("extra")) {
            extra = j["extra"];
        }
        // load customVLsPlayed if present
        if (j.HasKey("custom_vls_played") && JsonX::IsObject(j["custom_vls_played"])) {
            @customVLsPlayed = j["custom_vls_played"];
        }
        // load last for compat
        if (mapUid.Length == 0) mapUid = j.Get("mapUid", "1??1");
        if (mapName.Length == 0) mapName = j.Get("mapName", "1??1");
        trace('loaded json stats; floor vls played len: ' + floorVoiceLinesPlayed.Length);
    }

    void InitJsonFile() {
        trace('saving stats for ' + mapName + ' / ' + mapUid);
        SaveToDisk();
    }

    Json::Value@ ToJson() {
        Json::Value@ stats = Json::Object();
        stats["mapUid"] = mapUid;
        stats["mapName"] = mapName;
        stats["seconds_spent_in_map"] = msSpentInMap / 1000;
        stats["nb_jumps"] = nbJumps;
        stats["nb_falls"] = nbFalls;
        stats["nb_floors_fallen"] = nbFloorsFallen;
        stats["last_pb_set_ts"] = lastPbSetTs;
        stats["total_dist_fallen"] = totalDistFallen;
        stats["pb_height"] = pbHeight;
        stats["pb_floor"] = int(pbFloor);
        stats["pb_race_time"] = pbRaceTime;
        stats["pb_pos"] = Vec3ToJson(pbPos);
        stats["nb_resets"] = nbResets;
        stats["ggs_triggered"] = ggsTriggered;
        stats["title_gags_triggered"] = titleGagsTriggered;
        stats["title_gags_special_triggered"] = titleGagsSpecialTriggered;
        stats["bye_byes_triggered"] = byeByesTriggered;
        stats["monument_triggers"] = monumentTriggers.ToJson();
        stats["reached_floor_count"] = reachedFloorCount.ToJson();
        stats["floor_voice_lines_played"] = floorVoiceLinesPlayed.ToJson();
        stats["extra"] = extra;
        stats["custom_vls_played"] = customVLsPlayed;
        return stats;
    }

    bool get_isEzMap() {
        return mapUid == S_DD2EasyMapUid;
    }

    bool editStats = false;
    void DrawStatsUI() {
        DrawCenteredText("My Stats - " + mapName, f_DroidBigger);
        UI::PushStyleColor(UI::Col::FrameBg, vec4(.4, .2, .1, .8));
        UI::PushStyleColor(UI::Col::Border, vec4(.8, .4, .1, 1.));
        UI::PushStyleVar(UI::StyleVar::FrameBorderSize, 1.);
        editStats = UI::Checkbox("\\$f80Edit stats", editStats);
        UI::PopStyleVar(1);
        UI::PopStyleColor(2);
        if (!editStats) {
            UI::Columns(2, "myStatsColumns", true);
            UI::Text("Time spent in map");
            UI::Text("Finishes");
            UI::Text("Jumps");
            UI::Text("Falls");
            UI::Text("Floors fallen");
            UI::Text("Total distance fallen");
            UI::Text("Personal best height");
            UI::Text("Personal best floor");
            UI::Text("PB Race Time");
            UI::Text("Resets");
            UI::Text("Title gags triggered");
            UI::Text("Special Title Gags triggered");
            UI::Text("GGs triggered");
            UI::Text("Bye Byes triggered");
            UI::Text("Voice Lines Found");
            UI::NextColumn();
            UI::Text(Time::Format(msSpentInMap, false, true, true));
            UI::Text("" + GetNbFinishes());
            UI::Text("" + nbJumps);
            UI::Text("" + nbFalls);
            UI::Text("" + nbFloorsFallen);
            UI::Text(Text::Format("%.1f m", totalDistFallen));
            UI::Text(Text::Format("%.1f m", pbHeight));
            UI::Text(tostring(pbFloor));
            UI::Text(Time::Format(pbRaceTime));
            UI::Text("" + nbResets);
            UI::Text("" + titleGagsTriggered);
            UI::Text("" + titleGagsSpecialTriggered);
            UI::Text("" + ggsTriggered);
            UI::Text("" + byeByesTriggered);
            auto vlsPlayed = Count_CM_VoiceLinePlayed();
            UI::Text("" + vlsPlayed.x); // UI::Text("" + vlsPlayed.y);
            UI::Columns(1);
        } else {
            UI::Text("Time spent in map: Edit via Green Timer settings");
            UI::PushItemWidth(140. * UI_SCALE);
            nbJumps = UI::InputInt("Jumps", nbJumps);
            nbFalls = UI::InputInt("Falls", nbFalls);
            nbFloorsFallen = UI::InputInt("Floors fallen", nbFloorsFallen);
            totalDistFallen = UI::InputFloat("Total distance fallen", totalDistFallen);
            pbHeight = UI::InputFloat("Personal best height", pbHeight);
            pbFloor = UI::InputInt("Personal best floor", pbFloor);
            nbResets = UI::InputInt("Resets", nbResets);
            titleGagsTriggered = UI::InputInt("Title gags triggered", titleGagsTriggered);
            titleGagsSpecialTriggered = UI::InputInt("Special Title Gags triggered", titleGagsSpecialTriggered);
            ggsTriggered = UI::InputInt("GGs triggered", ggsTriggered);
            byeByesTriggered = UI::InputInt("Bye Byes triggered", byeByesTriggered);
            UI::PopItemWidth();
            DrawUintRow(floorVoiceLinesPlayed, "Floor voice lines played", 20., "fvls");
            UI::Separator();
            if (UI::Button("Copy From Main Stats")) {
                SaveToBackupStatsFile();
                _RunEzMapStatsMigration();
                Notify("Stats backed up to " + jsonFile + ".bak", 10000);
            }
        }
    }

    void DrawUintRow(uint[]@ arr, const string &in label, float itemWidth, const string &in id) {
        UI::Text(label);
        UI::SameLine();
        UI::PushItemWidth(itemWidth * UI_SCALE);
        for (uint i = 0; i < arr.Length; i++) {
            arr[i] = UI::InputInt("##" + i + id, arr[i], 0);
            UI::SameLine();
        }
        if (UI::Button(Icons::Plus + "##" + id)) {
            arr.InsertLast(0);
        }
        UI::PopItemWidth();
    }

    void SaveStatsSoon() {
        // start coroutine that waits a bit and then updates stats
        startnew(CoroutineFunc(UpdateStatsSaveLoop));
    }

    uint _lastStatsSave;
    uint _lastCallToSaveLoop;
    bool _isWaitingToSaveStats = false;

    void UpdateStatsSaveLoop() {
        _lastCallToSaveLoop = Time::Now;
        if (_isWaitingToSaveStats) return;
        _isWaitingToSaveStats = true;
        while (Time::Now - _lastCallToSaveLoop < STATS_UPDATE_MIN_WAIT && Time::Now - _lastStatsSave < STATS_UPDATE_INTERVAL) {
            yield();
        }
        _lastStatsSave = Time::Now;
        SaveToDisk();
        _lastStatsSave = Time::Now;
        _isWaitingToSaveStats = false;
    }

    void LogTimeInMapMs(uint64 deltaMs) {
        lastInMap = Time::Now;
        if (S_PauseTimerWhenWindowUnfocused && IsPauseMenuOpen(true)) return;
        if (S_PauseTimerWhileSpectating && Spectate::IsSpectatorOrMagicSpectator) return;
        msSpentInMap += deltaMs;
        this.SaveStatsSoon();
    }

    void SetTimeInMapMs(uint64 timeMs) {
        msSpentInMap = timeMs;
    }

    uint64 get_TimeInMapMs() {
        return msSpentInMap;
    }

    int GetNbFinishes() {
        return JGetInt(extra, "finish", 0);
    }

    void LogTriggeredSound(const string &in triggerName, const string &in audioFile) {
        // todo: player stats for triggering stuff
        // this is for arbitrary triggers
        // todo: add collections, etc
    }

    void LogTriggeredByeBye() {
        byeByesTriggered++;
        this.SaveStatsSoon();
    }

    void LogTriggeredTitle(const string &in name) {
        titleGagsTriggered++;
        this.SaveStatsSoon();
    }

    void LogTriggeredGG(const string &in name) {
        ggsTriggered++;
        this.SaveStatsSoon();
    }

    void LogTriggeredTitleSpecial(const string &in name) {
        titleGagsSpecialTriggered++;
        this.SaveStatsSoon();
    }

    void LogTriggeredMonuments(MonumentSubject subj) {
        while (int(subj) >= int(monumentTriggers.Length)) {
            monumentTriggers.InsertLast(0);
        }
        monumentTriggers[int(subj)]++;
        this.SaveStatsSoon();
    }

    void LogJumpStart() {
        nbJumps++;
    }

    void LogFallStart() {
        nbFalls++;
    }

    void LogFallEndedLessThanMin() {
        nbFalls--;
    }

    void LogRestart(int raceTime) {
        nbResets++;
        PushMessage(ReportRespawnMsg(raceTime));
    }

    void LogBleb() {
        IncrJsonIntCounter(extra, "blebs");
        this.SaveStatsSoon();
    }

    void LogQuack() {
        IncrJsonIntCounter(extra, "quacks");
        this.SaveStatsSoon();
    }

    void LogDebugTrigger() {
        IncrJsonIntCounter(extra, "debugTs");
        this.SaveStatsSoon();
    }

    void LogNormalFinish() {
        IncrJsonIntCounter(extra, "finish");
        this.SaveStatsSoon();
    }

    void LogDD2Finish() {
        IncrJsonIntCounter(extra, "finish");
        this.SaveStatsSoon();
    }

    void LogDD2EasyFinish() {
        IncrJsonIntCounter(extra, "finishSD");
        this.SaveStatsSoon();
    }

    void LogEasyVlPlayed(const string &in name) {
        IncrJsonIntCounter(extra, "evl/" + name);
        this.SaveStatsSoon();
    }

    uint _lastPlayerNoPbUpdateWarn = 0;
    float pbStartAlertLimit = 100.;

    void OnLocalPlayerPosUpdate(PlayerState@ player) {
        auto pos = player.pos;
        if (pos.y > this.pbHeight) {
            if (player.raceTime < 2000 || Time::Now - player.lastRespawn < 2000) {
                if (Time::Now - _lastPlayerNoPbUpdateWarn > 200) {
                    _lastPlayerNoPbUpdateWarn = Time::Now;
                    trace('ignoring PB height ' + pos.y + ' since raceTime or last respawn is less than 2s (ago)');
                }
                return;
            }
            bool lastPbWasAWhileAgo = pbHeight < pbStartAlertLimit || (Time::Now - lastPbSet > 180 * 1000);
            int floor = HeightToFloor(g_CustomMap, pos.y);
            lastPbSetTs = Time::Stamp;
            lastPbSet = Time::Now;
            pbFloor = floor;
            pbHeight = pos.y;
            pbRaceTime = player.raceTime;
            pbPos = pos;
            // 3 minutes
            if (lastPbWasAWhileAgo && pbHeight > pbStartAlertLimit) {
                EmitNewHeightPB(player);
            }
            this.OnNewPB();
            this.SaveStatsSoon();
        }
    }

    float get_PBHeight() {
        return pbHeight;
    }

    void AddFloorsFallen(int floors) {
        nbFloorsFallen += floors;
        this.SaveStatsSoon();
    }

    void AddDistanceFallen(float dist) {
        totalDistFallen += dist;
        this.SaveStatsSoon();
    }

    int get_TotalFalls() {
        return nbFalls;
    }

    int get_TotalFloorsFallen() {
        return nbFloorsFallen;
    }

    float get_TotalDistanceFallen() {
        return totalDistFallen;
    }

    // for when going up (don't add while falling)
    void LogFloorReached(int floor) {
        while (floor >= int(reachedFloorCount.Length)) {
            reachedFloorCount.InsertLast(0);
        }
        reachedFloorCount[floor]++;
        this.SaveStatsSoon();
    }

    void SetVoiceLinePlayed(int floor) {
        if (floor < 0) {
            return;
        }
        while (floor >= int(floorVoiceLinesPlayed.Length)) {
            floorVoiceLinesPlayed.InsertLast(0);
        }
        floorVoiceLinesPlayed[floor] += 1;
        this.SaveStatsSoon();
    }

    bool HasPlayedVoiceLine(int floor) {
        return GetFloorVoiceLineCount(floor) > 0;
    }

    int GetFloorVoiceLineCount(int floor) {
        if (floor < 0 || uint(floor) >= floorVoiceLinesPlayed.Length) {
            return 0;
        }
        return floorVoiceLinesPlayed[floor];
    }

    void Set_CM_VoiceLinePlayed(const string &in name) {
        if (customVLsPlayed.HasKey(name)) {
            customVLsPlayed[name] = int64(customVLsPlayed[name]) + 1;
        } else {
            customVLsPlayed[name] = 1;
        }
    }

    bool Has_CM_VoiceLinePlayed(const string &in name) {
        if (!customVLsPlayed.HasKey(name)) return false;
        auto j = customVLsPlayed[name];
        return JsonX::IsNumber(j) && int64(j) > 0;
    }

    int Get_CM_VoiceLinePlayedCount(const string &in name) {
        if (!customVLsPlayed.HasKey(name)) return 0;
        auto j = customVLsPlayed[name];
        if (!JsonX::IsNumber(j)) return 0;
        return int(j);
    }

    // returns (unique count, total count)
    int2 Count_CM_VoiceLinePlayed() {
        int2 count;
        auto keys = customVLsPlayed.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            count.x++;
            count.y += Get_CM_VoiceLinePlayedCount(keys[i]);
        }
        return count;
    }

    string[]@ GetAll_CM_VoiceLinesPlayed() {
        return customVLsPlayed.GetKeys();
    }


    void OnNewPB() {
        startnew(CoroutineFunc(this.UpdatePBHeightWaitLoop));
    }

    bool _isWaitingToUpdatePBH = false;
    uint _lastPBHUpdate = 0;
    uint _lastCallToPBHWaitLoop = 0;
    void UpdatePBHeightWaitLoop() {
        _lastCallToPBHWaitLoop = Time::Now;
        if (_isWaitingToUpdatePBH) return;
        _isWaitingToUpdatePBH = true;
        while (Time::Now - _lastCallToPBHWaitLoop < PBH_UPDATE_MIN_WAIT && Time::Now - _lastPBHUpdate < PBH_UPDATE_INTERVAL) {
            yield();
        }
        _lastPBHUpdate = Time::Now;
        PushMapPBToServer();
        _lastPBHUpdate = Time::Now;
        _isWaitingToUpdatePBH = false;
    }

    void PushMapPBToServer() {
        PushMessage(ReportMapCurrPosMsg(mapUid, pbPos, pbRaceTime));
    }
}

MapStats@ GetMapStats(CGameCtnChallenge@ map) {
    if (map is null) return null;
    return MapStatsCache::Get(map);
}
MapStats@ GetMapStats(const string &in mapUid, const string &in mapName) {
    return MapStatsCache::Get(mapUid, mapName);
}

namespace MapStatsCache {
    dictionary _cachedMapStats;

    MapStats@ Get(CGameCtnChallenge@ map) {
        return Get(map.MapInfo.MapUid, map.MapInfo.Name);
    }

    MapStats@ Get(const string &in mapUid, const string &in mapName) {
        if (_cachedMapStats.Exists(mapUid)) {
            return cast<MapStats>(_cachedMapStats[mapUid]);
        }
        MapStats@ stats = MapStats(mapUid, mapName);
        @_cachedMapStats[mapUid] = stats;
        return stats;
    }
}


// not used
bool Json_LoadFileIntoObj(const string &in filePath, Json::Value@ outJ) {
    if (!IO::FileExists(filePath)) return false;
    auto j = Json::FromFile(filePath);
    if (j.GetType() != Json::Type::Object) return false;
    if (outJ.GetType() != Json::Type::Object) return false;
    auto ks = j.GetKeys();
    for (uint i = 0; i < ks.Length; i++) {
        outJ[ks[i]] = j[ks[i]];
    }
    return true;
}


string GetMapStoragePath(const string &in mapUid, const string &in fileName) {
    return GetMapStoragePath(mapUid, "", fileName);
}

string GetMapStoragePath(const string &in mapUid, const string &in subFolder, const string &in fileName) {
    if (fileName.Contains("/") || fileName.Contains("\\")) {
        throw("GetMapStoragePath: fileName contains slash: " + fileName);
    }
    string path = "maps/" + mapUid;
    if (subFolder.Length > 0) path += "/" + subFolder;
    string folderPath = IO::FromStorageFolder(path);
    if (!IO::FolderExists(folderPath)) {
        IO::CreateFolder(folderPath);
    }
    return IO::FromStorageFolder(path + "/" + fileName);
}

string GetMapStatsFileName(const string &in mapUid) {
    return GetMapStoragePath(mapUid, "stats.json");
}
