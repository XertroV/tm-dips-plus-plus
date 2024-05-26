CustomMap@ g_CustomMap;

void CustomMap_SetOnNewCustomMap(CustomMap@ map) {
    @g_CustomMap = map;
    CurrMap::isDD2 = map.isDD2;
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

    CustomMap(CGameCtnChallenge@ map) {
        if (MapCustomInfo::ShouldActivateForMap(map)) {
            @stats = GetMapStats(map);
            isDD2 = stats.isDD2;
            useDD2Triggers = stats.isDD2 || stats.isEzMap;
            map.MwAddRef();
            startnew(CoroutineFuncUserdata(LoadCustomMapData), map);
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
        if ((@spec = MapCustomInfo::GetBuiltInInfo_Async(map.Id.Value)) !is null) {
            return true;
        }
        mapComment = map.Comments;
        @spec = MapCustomInfo::TryParse_Async(mapComment);
        for (uint i = 0; i < spec.floors.Length; i++) {
            floors.InsertLast(spec.floors[i]);
        }
        loadError = MapCustomInfo::lastParseFailReason;
        return spec !is null;
    }
}
