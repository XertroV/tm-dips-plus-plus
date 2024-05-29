/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/

const string STATS_FILE = IO::FromStorageFolder("stats.json");
const string AUX_STATS_DIR = IO::FromStorageFolder("map_stats");

namespace Stats {
    uint64 msSpentInMap = 0;
    uint nbJumps = 0;
    uint nbFalls = 0;
    uint nbFloorsFallen = 0;
    bool[] floorVoiceLinesPlayed = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false};
    uint[] reachedFloorCount = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint nbResets = 0;
    float pbHeight;
    MapFloor pbFloor = MapFloor::FloorGang;
    // local time, don't send to server
    uint lastPbSet = 0;
    uint lastPbSetTs = 0;
    float totalDistFallen;
    uint[] monumentTriggers = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint ggsTriggered = 0;
    uint titleGagsTriggered = 0;
    uint titleGagsSpecialTriggered = 0;
    uint byeByesTriggered = 0;
    Json::Value@ extra = Json::Object();
    [Setting hidden]
    uint lastLoadedDeepDip2Ts = 0;

    void DrawStatsUI() {
        DrawCenteredText("My Stats (DD2)", f_DroidBigger, 26.);
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
        UI::Text(Time::Format(msSpentInMap, false, true, true) + (Text::Format("\\$aaa\\$i  (total ms: %lld)", msSpentInMap)));
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

    Json::Value@ GetStatsJson() {
        Json::Value@ stats = Json::Object();
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

    void LoadStatsFromServer(Json::Value@ j) {
        trace("loading stats from server: " + Json::Write(j));
        // are these better than the stats we have?
        float statsHeight = j['pb_height'];
        warn("[server stats] Server height " + statsHeight + ", local height " + pbHeight);
        if (statsHeight > pbHeight) {
            warn("Updating with stats from server since pbHeight is greater");
            pbHeight = statsHeight;
            pbFloor = HeightToFloor(pbHeight);
            // pbFloor = MapFloor(int(j['pb_floor']));
            lastPbSetTs = j['last_pb_set_ts'];
            lastPbSet = Time::Now;
        }
        msSpentInMap = Math::Max(msSpentInMap, uint(j['seconds_spent_in_map']) * 1000);
        nbJumps = Math::Max(nbJumps, j['nb_jumps']);
        nbFalls = Math::Max(nbFalls, j['nb_falls']);
        nbFloorsFallen = Math::Max(nbFloorsFallen, j['nb_floors_fallen']);
        totalDistFallen = Math::Max(totalDistFallen, j['total_dist_fallen']);
        nbResets = Math::Max(nbResets, int(j['nb_resets']));
        ggsTriggered = Math::Max(ggsTriggered, j['ggs_triggered']);
        titleGagsTriggered = Math::Max(titleGagsTriggered, j['title_gags_triggered']);
        titleGagsSpecialTriggered = Math::Max(titleGagsSpecialTriggered, j['title_gags_special_triggered']);
        byeByesTriggered = Math::Max(byeByesTriggered, j['bye_byes_triggered']);

        if (j.HasKey("extra")) {
            CopyJsonValuesIfGreater(j["extra"], extra);
        }

        auto jMTs = j['monument_triggers'];
        for (uint i = 0; i < monumentTriggers.Length; i++) {
            if (i >= jMTs.Length) {
                break;
            }
            monumentTriggers[i] = Math::Max(monumentTriggers[i], jMTs[i]);
        }
        auto jRFC = j['reached_floor_count'];
        for (uint i = 0; i < reachedFloorCount.Length; i++) {
            if (i >= jRFC.Length) {
                break;
            }
            reachedFloorCount[i] = Math::Max(reachedFloorCount[i], jRFC[i]);
        }
        auto jFVL = j['floor_voice_lines_played'];
        for (uint i = 0; i < floorVoiceLinesPlayed.Length; i++) {
            if (i >= jFVL.Length) {
                break;
            }
            floorVoiceLinesPlayed[i] = floorVoiceLinesPlayed[i] || bool(jFVL[i]);
        }

        if (!F_HaveDoneEasyMapCheck) {
            F_HaveDoneEasyMapCheck = true;
            Meta::SaveSettings();
        }

        trace("Loaded server stats; after: " + Json::Write(GetStatsJson()));
    }

    float pbHeightFromJsonFile;

    void LoadStatsFromJson(Json::Value@ j) {
        if (j.HasKey("ReportStats")) @j = j['ReportStats'];
        if (j.HasKey("stats")) @j = j['stats'];
        trace("loading stats: " + Json::Write(j));
        msSpentInMap = uint(j["seconds_spent_in_map"]) * 1000;
        nbJumps = j["nb_jumps"];
        nbFalls = j["nb_falls"];
        nbFloorsFallen = j["nb_floors_fallen"];
        lastPbSetTs = j["last_pb_set_ts"];
        totalDistFallen = j["total_dist_fallen"];
        // don't restore pb height for DD2, get from server
        // pbHeight = j["pb_height"];
        // pbFloor = HeightToFloor(pbHeight);
        // save it for migration though
        pbHeightFromJsonFile = j["pb_height"];
        nbResets = j["nb_resets"];
        ggsTriggered = j["ggs_triggered"];
        titleGagsTriggered = j["title_gags_triggered"];
        titleGagsSpecialTriggered = j["title_gags_special_triggered"];
        byeByesTriggered = j["bye_byes_triggered"];
        monumentTriggers = JsonToUintArray(j["monument_triggers"]);
        reachedFloorCount = JsonToUintArray(j["reached_floor_count"]);
        floorVoiceLinesPlayed = JsonToBoolArray(j["floor_voice_lines_played"]);
        if (j.HasKey("extra")) {
            extra = j["extra"];
        }
        trace('loaded json stats; floor vls played len: ' + floorVoiceLinesPlayed.Length);
    }

    void SaveToDisk() {
        Json::ToFile(STATS_FILE, GetStatsJson());
    }

    void OnStartTryRestoreFromFile() {
        if (IO::FileExists(STATS_FILE)) {
            auto statsJson = Json::FromFile(STATS_FILE);
            if (statsJson !is null && statsJson.GetType() == Json::Type::Object) {
                dev_trace('loading stats');
                LoadStatsFromJson(statsJson);
                dev_trace('loaded stats');
            }
        }
    }

    void BackupForSafety() {
        if (IO::FileExists(STATS_FILE)) {
            IO::File f(STATS_FILE, IO::FileMode::Read);
            IO::File f2(STATS_FILE + "." + Time::Stamp, IO::FileMode::Write);
            f2.Write(f.ReadToEnd());
        }
    }

    void LogTimeInMapMs(uint64 deltaMs) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogTimeInMapMs(deltaMs);
            return;
        }
        lastLoadedDeepDip2Ts = Time::Now;
        if (S_PauseTimerWhenWindowUnfocused && IsPauseMenuOpen(true)) return;
        if (S_PauseTimerWhileSpectating && Spectate::IsSpectatorOrMagicSpectator) return;
        msSpentInMap += deltaMs;
        UpdateStatsSoon();
    }

    void SetTimeInMapMs(uint64 timeMs) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.SetTimeInMapMs(timeMs);
            return;
        }
        msSpentInMap = timeMs;
    }

    uint64 GetTimeInMapMs() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.stats.TimeInMapMs;
        }
        return msSpentInMap;
    }

    void LogTriggeredSound(const string &in triggerName, const string &in audioFile) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogTriggeredSound(triggerName, audioFile);
            return;
        }
        // todo: player stats for triggering stuff
        // this is for arbitrary triggers
        // todo: add collections, etc
    }

    void LogTriggeredByeBye() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogTriggeredByeBye();
            return;
        }
        byeByesTriggered++;
        UpdateStatsSoon();
    }

    void LogTriggeredTitle(const string &in name) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogTriggeredTitle(name);
            return;
        }
        titleGagsTriggered++;
        UpdateStatsSoon();
    }

    void LogTriggeredGG(const string &in name) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogTriggeredGG(name);
            return;
        }
        ggsTriggered++;
        UpdateStatsSoon();
    }

    void LogTriggeredTitleSpecial(const string &in name) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogTriggeredTitleSpecial(name);
            return;
        }
        titleGagsSpecialTriggered++;
        UpdateStatsSoon();
    }

    void LogTriggeredMonuments(MonumentSubject subj) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogTriggeredMonuments(subj);
            return;
        }
        monumentTriggers[int(subj)]++;
        UpdateStatsSoon();
    }

    void LogJumpStart() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogJumpStart();
            return;
        }
        nbJumps++;
    }

    void LogFallStart() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogFallStart();
            return;
        }
        nbFalls++;
    }

    void LogFallEndedLessThanMin() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogFallEndedLessThanMin();
            return;
        }
        nbFalls--;
    }

    void LogRestart(int raceTime) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogRestart(raceTime);
            return;
        }
        nbResets++;
        PushMessage(ReportRespawnMsg(raceTime));
    }

    void LogBleb() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogBleb();
            return;
        }
        IncrJsonIntCounter(extra, "blebs");
        UpdateStatsSoon();
    }

    void LogQuack() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogQuack();
            return;
        }
        IncrJsonIntCounter(extra, "quacks");
        UpdateStatsSoon();
    }

    void LogDebugTrigger() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogDebugTrigger();
            return;
        }
        IncrJsonIntCounter(extra, "debugTs");
        UpdateStatsSoon();
    }

    void LogFinish() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogNormalFinish();
            return;
        }
    }

    void LogDD2Finish() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogDD2Finish();
            return;
        }
        IncrJsonIntCounter(extra, "finish");
        UpdateStatsSoon();
    }

    void LogDD2EasyFinish() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogDD2EasyFinish();
            return;
        }
        IncrJsonIntCounter(extra, "finishSD");
        UpdateStatsSoon();
    }

    void LogEasyVlPlayed(const string &in name) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogEasyVlPlayed(name);
            return;
        }
        IncrJsonIntCounter(extra, "evl/" + name);
        UpdateStatsSoon();
    }

    // just after maji floor welcome sign
    const float PB_START_ALERT_LIMIT = 112.;
    uint lastPlayerNoPbUpdateWarn = 0;

    void OnLocalPlayerPosUpdate(PlayerState@ player) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.OnLocalPlayerPosUpdate(player);
            return;
        }
        auto pos = player.pos;
        if (pos.y > pbHeight) {
            if (player.raceTime < 2000 || Time::Now - player.lastRespawn < 2000) {
                if (Time::Now - lastPlayerNoPbUpdateWarn > 200) {
                    lastPlayerNoPbUpdateWarn = Time::Now;
                    trace('ignoring PB height ' + pos.y + ' since raceTime or last respawn is less than 2s (ago)');
                }
                return;
            }
            bool lastPbWasAWhileAgo = pbHeight < PB_START_ALERT_LIMIT || (Time::Now - lastPbSet > 180 * 1000);
            auto floor = HeightToFloor(pos.y);
            lastPbSetTs = Time::Stamp;
            lastPbSet = Time::Now;
            pbFloor = floor;
            pbHeight = pos.y;
            // 3 minutes
            if (lastPbWasAWhileAgo && pbHeight > PB_START_ALERT_LIMIT) {
                EmitNewHeightPB(player);
            }
            PBUpdate::UpdatePBHeightSoon();
        }
    }

    float GetPBHeight() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.stats.PBHeight;
        }
        return pbHeight;
    }

    void AddFloorsFallen(int floors) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.AddFloorsFallen(floors);
            return;
        }
        nbFloorsFallen += floors;
        UpdateStatsSoon();
    }

    void AddDistanceFallen(float dist) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.AddDistanceFallen(dist);
            return;
        }
        totalDistFallen += dist;
        UpdateStatsSoon();
    }

    int GetTotalFalls() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.stats.TotalFalls;
        }
        return nbFalls;
    }

    int GetTotalFloorsFallen() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.stats.TotalFloorsFallen;
        }
        return nbFloorsFallen;
    }

    float GetTotalDistanceFallen() {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.stats.TotalDistanceFallen;
        }
        return totalDistFallen;
    }

    // for when going up (don't add while falling)
    void LogFloorReached(int floor) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.LogFloorReached(floor);
            return;
        }
        reachedFloorCount[floor]++;
        UpdateStatsSoon();
    }

    void SetVoiceLinePlayed(int floor) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            g_CustomMap.stats.SetVoiceLinePlayed(floor);
            return;
        }
        if (floor < 0 || floor >= floorVoiceLinesPlayed.Length) {
            return;
        }
        floorVoiceLinesPlayed[floor] = true;
        UpdateStatsSoon();
    }

    bool HasPlayedVoiceLine(int floor) {
        if (g_CustomMap !is null && !g_CustomMap.isDD2) {
            return g_CustomMap.stats.HasPlayedVoiceLine(floor);
        }
        if (floor < 0 || floor >= floorVoiceLinesPlayed.Length) {
            return false;
        }
        return floorVoiceLinesPlayed[floor];
    }
}

void UpdateStatsSoon() {
    // start coroutine that waits a bit and then updates stats
    startnew(UpdateStatsWaitLoop);
}


const uint STATS_UPDATE_INTERVAL = 1000 * 20;
const uint STATS_UPDATE_MIN_WAIT = 1000 * 5;
bool isWaitingToUpdateStats = false;
uint lastStatsUpdate = 0;
uint lastCallToWaitLoop = 0;

void UpdateStatsWaitLoop() {
    lastCallToWaitLoop = Time::Now;
    if (isWaitingToUpdateStats) return;
    isWaitingToUpdateStats = true;
    while (Time::Now - lastCallToWaitLoop < STATS_UPDATE_MIN_WAIT && Time::Now - lastStatsUpdate < STATS_UPDATE_INTERVAL) {
        yield();
    }
    lastStatsUpdate = Time::Now;
    PushStatsUpdateToServer();
    lastStatsUpdate = Time::Now;
    isWaitingToUpdateStats = false;
}

const uint PBH_UPDATE_INTERVAL = 2000;
const uint PBH_UPDATE_MIN_WAIT = 1000;

namespace PBUpdate {
    void UpdatePBHeightSoon() {
        startnew(PBUpdate::UpdatePBHeightWaitLoop);
    }

    bool isWaitingToUpdatePBH = false;
    uint lastPBHUpdate = 0;
    uint lastCallToPBHWaitLoop = 0;

    void UpdatePBHeightWaitLoop() {
        lastCallToPBHWaitLoop = Time::Now;
        if (isWaitingToUpdatePBH) return;
        isWaitingToUpdatePBH = true;
        while (Time::Now - lastCallToPBHWaitLoop < PBH_UPDATE_MIN_WAIT && Time::Now - lastPBHUpdate < PBH_UPDATE_INTERVAL) {
            yield();
        }
        lastPBHUpdate = Time::Now;
        PushPBHeightUpdateToServer();
        lastPBHUpdate = Time::Now;
        isWaitingToUpdatePBH = false;
    }
}


// Okay for unofficial
void EmitNewHeightPB(PlayerState@ player) {
    // dev_trace("New PB at " + Stats::GetPBHeight() + " on floor " + Stats::GetPBFloor());
    // EmitStatusAnimation(PersonalBestStatusAnim(player));
    EmitStatusAnimation(PersonalBestStatusAnim());
}





class LBEntry {
    string name;
    string wsid;
    float height;
    uint rank;
    uint ts;
    uint raceTimeAtHeight;
    vec3 color;
    vec3 pos;
    int race_time;

    void SetFromJson(Json::Value@ j) {
        name = j["name"];
        wsid = j["wsid"];
        rank = j["rank"];
        ts = j["ts"];
        if (j.HasKey("color")) {
            color = JsonToVec3(j["color"]);
        }
        if (j.HasKey("height")) {
            height = j["height"];
        }
        if (j.HasKey("pos")) {
            pos = JsonToVec3(j["pos"]);
            height = pos.y;
        }
        race_time = j.Get("race_time", -1);
    }
}
