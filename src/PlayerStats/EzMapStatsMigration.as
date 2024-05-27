[Setting hidden]
bool F_HasMigratedEzMapStats = false;

void RunEzMapStatsMigration() {
    if (F_HasMigratedEzMapStats) return;
    if (!F_PlayedDD2BeforeEasyMap
        || (S_EnableForEasyMap && S_EnableSavingStatsOnEasyMap)
    ) {
        _RunEzMapStatsMigration();
    }
}

void _RunEzMapStatsMigration() {
    auto map = CustomMap(S_DD2EasyMapUid, "DD2: Shallow Dip");
    if (map.stats is null) {
        throw("Unexpected: ez map stats is null");
    }
    if (IO::FileExists(STATS_FILE)) {
        warn("Migrating stats for shallow dip");
        auto j = Json::FromFile(STATS_FILE);
        if (j.HasKey("ReportStats")) @j = j['ReportStats'];
        if (j.HasKey("stats")) @j = j['stats'];
        ConvertBoolToUintArray(j, "floor_voice_lines_played");
        map.stats.LoadJsonFromFile(j);
        map.stats.SaveToDisk();
        warn("Migrate saved to " + map.stats.jsonFile);
    }
    F_HasMigratedEzMapStats = true;
    Meta::SaveSettings();
}

void ConvertBoolToUintArray(Json::Value@ j, const string &in key) {
    if (!j.HasKey(key)) {
        warn("Key not found: " + key);
        return;
    }
    auto arr = j[key];
    if (arr.GetType() != Json::Type::Array) {
        warn("Key is not an array: " + key + " / type: " + tostring(arr.GetType()));
        return;
    }
    if (arr is null) return;
    auto new_arr = Json::Array();
    for (uint i = 0; i < arr.Length; i++) {
        new_arr.Add(bool(arr[i]) ? 1 : 0);
    }
    j[key] = new_arr;
}
