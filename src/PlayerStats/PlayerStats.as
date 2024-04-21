namespace Stats {
    uint nbFalls = 0;
    uint nbFloorsFallen = 0;


    void LogTriggeredSound(const string &in triggerName, const string &in audioFile) {
        // todo: player stats for triggering stuff
        // this is for arbitrary triggers
        // todo: add collections, etc
    }

    void LogTriggeredTitle(const string &in name) {

    }

    void LogTriggeredGG(const string &in name) {

    }

    void LogTriggeredMonuments(MonumentSubject subj) {

    }

    void LogFallStart() {
        nbFalls++;
    }

    void AddFloorsFallen(int floors) {
        nbFloorsFallen += floors;
    }

    int GetTotalFalls() {
        return nbFalls;
    }

    int GetTotalFloorsFallen() {
        return nbFloorsFallen;
    }
}
