namespace CurrMap {
    uint lastMapMwId = 0;

    void CheckMapChange(CGameCtnChallenge@ map) {
        if (map is null) {
            if (lastMapMwId != 0) {
                lastMapMwId = 0;
                CustomMap_SetOnNewCustomMap(null);
            }
            return;
        }
        if (lastMapMwId == map.Id.Value) return;
        lastMapMwId = map.Id.Value;
        // don't set it for main dd2 for compatibility
        if (map.MapInfo.MapUid == DD2_MAP_UID) {
            CustomMap_SetOnNewCustomMap(null);
        } else {
            CustomMap_SetOnNewCustomMap(CustomMap(map));
        }
    }
}
