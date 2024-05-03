/*  !! IMPORTANT !!
Please respect the integrity of the competition.
Please refuse any requests to assist in evading any
measures this plugin takes to protect the integrity
of the competition.
Please do not distribute altered copies of the DD2 map.
Thank you.
- XertroV
*/


namespace Stats {
    uint64 msSpentInMap = 0;
    uint nbJumps = 0;
    uint nbFalls = 0;
    uint nbFloorsFallen = 0;
    bool[] floorVoiceLinesPlayed = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false};
    uint[] reachedFloorCount = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint nbResets = 0;
    float pbHeight;
    MapFloor pbFloor = MapFloor::FloorGang;
    // local time, don't send to server
    uint lastPbSet = 0;
    uint lastPbSetTs = 0;
    float totalDistFallen;
    uint[] monumentTriggers = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint ggsTriggered = 0;
    uint titleGagsTriggered = 0;
    uint titleGagsSpecialTriggered = 0;
    uint byeByesTriggered = 0;

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
        return stats;
    }

    void LoadStatsFromJson(Json::Value@ j) {
        msSpentInMap = uint(j["seconds_spent_in_map"]) * 1000;
        nbJumps = j["nb_jumps"];
        nbFalls = j["nb_falls"];
        nbFloorsFallen = j["nb_floors_fallen"];
        lastPbSetTs = j["last_pb_set_ts"];
        totalDistFallen = j["total_dist_fallen"];
        pbHeight = j["pb_height"];
        pbFloor = MapFloor(int(j["pb_floor"]));
        nbResets = j["nb_resets"];
        ggsTriggered = j["ggs_triggered"];
        titleGagsTriggered = j["title_gags_triggered"];
        titleGagsSpecialTriggered = j["title_gags_special_triggered"];
        byeByesTriggered = j["bye_byes_triggered"];
        monumentTriggers = JsonToUintArray(j["monument_triggers"]);
        reachedFloorCount = JsonToUintArray(j["reached_floor_count"]);
        floorVoiceLinesPlayed = JsonToBoolArray(j["floor_voice_lines_played"]);
    }

    // from server
    LBEntry@[] globalLB;

    void LogTimeInMapMs(uint deltaMs) {
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

    // just after maji floor welcome sign
    const float PB_START_ALERT_LIMIT = 112.;

    void OnLocalPlayerPosUpdate(PlayerState@ player) {
        auto pos = player.pos;
        if (pos.y > pbHeight) {
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
    float height;
    uint raceTimeAtHeight;
}
