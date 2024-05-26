CustomMap@ g_CustomMap;

void CustomMap_SetOnNewCustomMap(CustomMap@ map) {
    @g_CustomMap = map;
}

class CustomMap {
    bool isDD2;
    bool useDD2Triggers;
    bool hasCustomData;
    MapStats@ stats;
    string mapComment;
    MapCustomInfo::DipsSpec@ spec;
    string loadError;
    float[] floors;
    bool lastFloorEnd = false;

    CustomMap(CGameCtnChallenge@ map) {
        if (MapCustomInfo::ShouldActivateForMap(map)) {
            @stats = GetMapStats(map);
            isDD2 = stats.isDD2;
            useDD2Triggers = stats.isDD2 || stats.isEzMap;
            map.MwAddRef();
            startnew(CoroutineFuncUserdata(LoadCustomMapData), map);
        }
    }

    CustomMap(const string &in mapUid, const string &in mapName) {
        if (MapCustomInfo::ShouldActivateForMap(mapUid, "")) {
            @stats = GetMapStats(mapUid, mapName);
            isDD2 = stats.isDD2;
            useDD2Triggers = stats.isDD2 || stats.isEzMap;
            startnew(CoroutineFuncUserdata(CheckForUploadedMapData), array<string> = {mapUid});
        }
    }

    ~CustomMap() {

    }

    // for hardcoded heights and things
    bool get_IsEnabledNotDD2() {
        return hasCustomData && !useDD2Triggers;
    }

    bool get_IsEnabled() {
        return hasCustomData || useDD2Triggers;
    }

    // can yield
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
        if (spec is null) {
            @spec = MapCustomInfo::TryParse_Async(mapComment);
        }
        loadError = MapCustomInfo::lastParseFailReason;
        if (spec is null) {
            startnew(CoroutineFuncUserdata(CheckForUploadedMapData), array<string> = {stats.mapUid});
            return false;
        }
        for (uint i = 0; i < spec.floors.Length; i++) {
            floors.InsertLast(spec.floors[i]);
        }
        lastFloorEnd = spec.lastFloorEnd;
        return true;
    }
}

const string MapInfosUploadedURL = "https://assets.xk.io/d++maps/";

void CheckForUploadedMapData(ref@ data) {
    auto mapUid = cast<string[]>(data)[0];
    auto url = MapInfosUploadedURL + mapUid + ".txt";
    Net::HttpRequest@ req = Net::HttpGet(url);
    while (!req.Finished()) {
        yield();
    }
    auto status = req.ResponseCode();
    if (status < 200 || status > 299) {
        // error
        if (status != 404) warn("Failed to load map data from " + url + " - status " + status + " response: " + req.String());
        return;
    }
    MapCustomInfo::AddNewMapComment(mapUid, req.String());
    trace('found and added map data for ' + mapUid + ' from ' + url);
    CurrMap::lastMapMwId = 0;
}
