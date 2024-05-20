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
        nbResets = Math::Max(nbResets, j['nb_resets']);
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
            S_EnableForEasyMap = pbHeight < 90.;
            F_HaveDoneEasyMapCheck = true;
            MatchDD2::lastMapMwId = 0;
            Meta::SaveSettings();
        }
    }

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
        // don't restore pb height
        // pbHeight = j["pb_height"];
        // pbFloor = MapFloor(int(j["pb_floor"]));
        pbFloor = HeightToFloor(pbHeight);
        nbResets = j["nb_resets"];
        ggsTriggered = j["ggs_triggered"];
        titleGagsTriggered = j["title_gags_triggered"];
        titleGagsSpecialTriggered = j["title_gags_special_triggered"];
        byeByesTriggered = j["bye_byes_triggered"];
        monumentTriggers = JsonToUintArray(j["monument_triggers"]);
        reachedFloorCount = JsonToUintArray(j["reached_floor_count"]);
        floorVoiceLinesPlayed = JsonToBoolArray(j["floor_voice_lines_played"]);
        dev_trace('loaded json stats; floor vls played len: ' + floorVoiceLinesPlayed.Length);
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

    // from server
    LBEntry@[] globalLB;

    void LogTimeInMapMs(uint deltaMs) {
        lastLoadedDeepDip2Ts = Time::Now;
        if (S_PauseTimerWhenWindowUnfocused && IsPauseMenuOpen(true)) return;
        if (S_PauseTimerWhileSpectating && Spectate::IsSpectatorOrMagicSpectator) return;
        msSpentInMap += deltaMs;
        UpdateStatsSoon();
    }

    void LogTriggeredSound(const string &in triggerName, const string &in audioFile) {
        // todo: player stats for triggering stuff
        // this is for arbitrary triggers
        // todo: add collections, etc
    }

    void LogTriggeredByeBye() {
        byeByesTriggered++;
        UpdateStatsSoon();
    }

    void LogTriggeredTitle(const string &in name) {
        // todo
        titleGagsTriggered++;
        UpdateStatsSoon();
    }

    void LogTriggeredGG(const string &in name) {
        // todo
        ggsTriggered++;
        UpdateStatsSoon();
    }

    void LogTriggeredTitleSpecial(const string &in name) {
        // todo
        titleGagsSpecialTriggered++;
        UpdateStatsSoon();
    }

    void LogTriggeredMonuments(MonumentSubject subj) {
        monumentTriggers[int(subj)]++;
        UpdateStatsSoon();
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
        UpdateStatsSoon();
    }

    void LogQuack() {
        IncrJsonIntCounter(extra, "quacks");
        UpdateStatsSoon();
    }

    void LogDebugTrigger() {
        IncrJsonIntCounter(extra, "debugTs");
        UpdateStatsSoon();
    }

    // just after maji floor welcome sign
    const float PB_START_ALERT_LIMIT = 112.;
    uint lastPlayerNoPbUpdateWarn = 0;

    void OnLocalPlayerPosUpdate(PlayerState@ player) {
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
            UpdatePBHeightSoon();
        }
    }

    float GetPBHeight() {
        return pbHeight;
    }

    void AddFloorsFallen(int floors) {
        nbFloorsFallen += floors;
        UpdateStatsSoon();
    }

    void AddDistanceFallen(float dist) {
        totalDistFallen += dist;
        UpdateStatsSoon();
    }

    int GetTotalFalls() {
        return nbFalls;
    }

    int GetTotalFloorsFallen() {
        return nbFloorsFallen;
    }

    float GetTotalDistanceFallen() {
        return totalDistFallen;
    }

    // for when going up (don't add while falling)
    void LogFloorReached(int floor) {
        reachedFloorCount[floor]++;
        UpdateStatsSoon();
    }

    void SetVoiceLinePlayed(int floor) {
        if (floor < 0 || floor >= floorVoiceLinesPlayed.Length) {
            return;
        }
        floorVoiceLinesPlayed[floor] = true;
        UpdateStatsSoon();
    }

    bool HasPlayedVoiceLine(int floor) {
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

void UpdatePBHeightSoon() {
    startnew(UpdatePBHeightWaitLoop);
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



void EmitNewHeightPB(PlayerState@ player) {
    dev_trace("New PB at " + Stats::pbHeight + " on floor " + Stats::pbFloor);
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

    void SetFromJson(Json::Value@ j) {
        name = j["name"];
        wsid = j["wsid"];
        height = j["height"];
        rank = j["rank"];
        ts = j["ts"];
        if (j.HasKey("color")) {
            color = JsonToVec3(j["color"]);
        }
    }
}
