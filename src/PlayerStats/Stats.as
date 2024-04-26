namespace Stats {
    uint nbFalls = 0;
    uint nbFloorsFallen = 0;
    bool[] floorVoiceLinesPlayed = {false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false};
    uint[] reachedFloorCount = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint nbResets = 0;
    float pbHeight;
    MapFloor pbFloor = MapFloor::FloorGang;
    uint lastPbSet = 0;
    float totalDistFallen;
    uint[] monumentTriggers = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint ggsTriggered = 0;
    uint titleGagsTriggered = 0;

    void LogTriggeredSound(const string &in triggerName, const string &in audioFile) {
        // todo: player stats for triggering stuff
        // this is for arbitrary triggers
        // todo: add collections, etc
    }

    void LogTriggeredTitle(const string &in name) {
        // todo
        titleGagsTriggered++;
    }

    void LogTriggeredGG(const string &in name) {
        // todo
        ggsTriggered++;
    }

    void LogTriggeredMonuments(MonumentSubject subj) {
        monumentTriggers[int(subj)]++;
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
            bool lastPbWasAWhileAgo = pbHeight < PB_START_ALERT_LIMIT || Time::Now - lastPbSet > 180 * 1000;
            auto floor = HeightToFloor(pos.y);
            lastPbSet = Time::Now;
            pbFloor = floor;
            pbHeight = pos.y;
            // 3 minutes
            if (lastPbWasAWhileAgo && pbHeight > PB_START_ALERT_LIMIT) {
                EmitNewHeightPB(player);
            }
        }
    }

    float GetPBHeight() {
        return pbHeight;
    }

    void AddFloorsFallen(int floors) {
        nbFloorsFallen += floors;
    }

    void AddDistanceFallen(float dist) {
        totalDistFallen += dist;
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
    }

    void SetVoiceLinePlayed(int floor) {
        if (floor < 0 || floor >= floorVoiceLinesPlayed.Length) {
            return;
        }
        floorVoiceLinesPlayed[floor] = true;
    }

    bool HasPlayedVoiceLine(int floor) {
        if (floor < 0 || floor >= floorVoiceLinesPlayed.Length) {
            return false;
        }
        return floorVoiceLinesPlayed[floor];
    }
}



void EmitNewHeightPB(PlayerState@ player) {
    EmitStatusAnimation(PersonalBestStatusAnim(player));
}



