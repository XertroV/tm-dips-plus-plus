// use GetMapStats instead of instantiating directly
class MapStats {
    string mapUid;
    string mapName;
    string jsonFile;
    bool isDD2 = false;
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
    // local time, don't send to server
    uint lastPbSet = 0;
    uint lastInMap = Time::Stamp;

    MapStats(CGameCtnChallenge@ map) {
        mapUid = map.MapInfo.MapUid;
        _mapMwId = map.Id.Value;
        isDD2 = mapUid == DD2_MAP_UID;
        mapName = map.MapInfo.Name;
        jsonFile = GetMapStatsFileName(mapUid);
        if (!IO::FileExists(jsonFile)) {
            InitJsonFile();
        } else {
            Json::Value@ j = Json::FromFile(jsonFile);
            LoadJsonFromFile(j);
        }
        startnew(CoroutineFunc(MapWatchLoop));
    }

    ~MapStats() {
        SaveToDisk();
    }

    void MapWatchLoop() {
        while (_mapMwId == CurrMap::lastMapMwId) {
            yield();
        }
        SaveToDisk();
    }

    void SaveToDisk() {
        Json::ToFile(jsonFile, this.ToJson());
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
        if (j.HasKey("extra")) {
            extra = j["extra"];
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
        stats["nb_resets"] = nbResets;
        stats["ggs_triggered"] = ggsTriggered;
        stats["title_gags_triggered"] = titleGagsTriggered;
        stats["title_gags_special_triggered"] = titleGagsSpecialTriggered;
        stats["bye_byes_triggered"] = byeByesTriggered;
        stats["monument_triggers"] = monumentTriggers.ToJson();
        stats["reached_floor_count"] = reachedFloorCount.ToJson();
        stats["floor_voice_lines_played"] = floorVoiceLinesPlayed.ToJson();
        stats["extra"] = extra;
        return stats;
    }

    bool get_isEzMap() {
        return mapUid == S_DD2EasyMapUid;
    }

    void DrawStatsUI() {
        DrawCenteredText("My Stats", f_DroidBigger, 26.);
        UI::Columns(2, "myStatsColumns", true);
        UI::Text("Time spent in map");
        UI::Text("Jumps");
        UI::Text("Falls");
        UI::Text("Floors fallen");
        UI::Text("Total distance fallen");
        UI::Text("Personal best height");
        UI::Text("Personal best floor");
        UI::Text("Resets");
        UI::Text("Title gags triggered");
        UI::Text("Special Title Gags triggered");
        UI::Text("GGs triggered");
        UI::Text("Bye Byes triggered");
        UI::NextColumn();
        UI::Text(Time::Format(msSpentInMap, false, true, true));
        UI::Text("" + nbJumps);
        UI::Text("" + nbFalls);
        UI::Text("" + nbFloorsFallen);
        UI::Text(Text::Format("%.1f m", totalDistFallen));
        UI::Text(Text::Format("%.1f m", pbHeight));
        UI::Text(tostring(pbFloor));
        UI::Text("" + nbResets);
        UI::Text("" + titleGagsTriggered);
        UI::Text("" + titleGagsSpecialTriggered);
        UI::Text("" + ggsTriggered);
        UI::Text("" + byeByesTriggered);
        UI::Columns(1);
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

    void LogTimeInMapMs(uint deltaMs) {
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
        while (int(subj) >= monumentTriggers.Length) {
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
            // 3 minutes
            if (lastPbWasAWhileAgo && pbHeight > pbStartAlertLimit) {
                EmitNewHeightPB(player);
            }
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
        while (floor >= reachedFloorCount.Length) {
            reachedFloorCount.InsertLast(0);
        }
        reachedFloorCount[floor]++;
        this.SaveStatsSoon();
    }

    void SetVoiceLinePlayed(int floor) {
        if (floor < 0) {
            return;
        }
        while (floor >= floorVoiceLinesPlayed.Length) {
            floorVoiceLinesPlayed.InsertLast(0);
        }
        floorVoiceLinesPlayed[floor] += 1;
        this.SaveStatsSoon();
    }

    bool HasPlayedVoiceLine(int floor) {
        return GetFloorVoiceLineCount(floor) > 0;
    }

    int GetFloorVoiceLineCount(int floor) {
        if (floor < 0 || floor >= floorVoiceLinesPlayed.Length) {
            return 0;
        }
        return floorVoiceLinesPlayed[floor];
    }
}

MapStats@ GetMapStats(CGameCtnChallenge@ map) {
    if (map is null) return null;
    return MapStatsCache::Get(map);
}

namespace MapStatsCache {
    dictionary _cachedMapStats;

    MapStats@ Get(CGameCtnChallenge@ map) {
        if (_cachedMapStats.Exists(map.MapInfo.MapUid)) {
            return cast<MapStats>(_cachedMapStats[map.MapInfo.MapUid]);
        }
        MapStats@ stats = MapStats(map);
        @_cachedMapStats[map.MapInfo.MapUid] = stats;
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
